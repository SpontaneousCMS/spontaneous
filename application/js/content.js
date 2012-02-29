// console.log('Loading Content...')

Spontaneous.Content = (function($, S) {
	var dom = S.Dom;

	var Content = new JS.Class({
		include: Spontaneous.Properties,

		initialize: function(content) {
			this.content = content;
		},

		uid: function() {
			return (this.container ? this.container.uid() : '') + '/' + this.content.id;
		},
		id: function() {
			return this.content.id;
		},
		is_page: function() {
			return this.type().is_page();
		},

		target: function() {
			return this.content.target;
		},
		developer_description: function() {
			return this.type().type + "["+this.id()+']'
		},
		developer_edit_url: function() {
			return this.type().edit_url();
		},
		type: function() {
			return S.Types.type(this.content.type);
		}.cache(),

		slug: function() {
			return this.content.slug;
		},

		constantize: function(type) {
			var parts = type.split(/\./), obj = window;
			for (var i = 0, ii = parts.length; i < ii; i++) {
				obj = obj[parts[i]];
			}
			return obj;
		},

		unload: function() {
			$.each(this.field_list(), function(i, f) { f.unload(); });
			$.each(this.entries(), function(i, e) { e.unload(); });
		},

		has_fields: function() {
			return this.field_list().length > 0;
		},
		field_list: function() {
			var type = this.type(), prototypes = type.field_prototypes, names = type.field_names;
			var fields = this.fields(), list = [];
			for (var i = 0, ii = names.length; i < ii; i++) {
				list.push(fields[names[i]]);
			}
			return list;
		}.cache(),

		text_fields: function() {
			var fields = [], all_fields = this.field_list();
			for (var i = 0, ii = all_fields.length; i < ii; i++) {
				var f = all_fields[i];
				if (!f.is_image()) {
					fields.push(f);
				}
			}
			return fields;
		},
		image_fields: function() {
			var fields = [], all_fields = this.field_list();
			for (var i = 0, ii = all_fields.length; i < ii; i++) {
				var f = all_fields[i];
				if (f.is_image()) {
					fields.push(f);
				}
			}
			return fields;
		},
		file_fields: function() {
			var fields = [], all_fields = this.field_list();
			for (var i = 0, ii = all_fields.length; i < ii; i++) {
				var f = all_fields[i];
				if (f.is_file()) {
					fields.push(f);
				}
			}
			return fields;
		},
		fields: function() {
			var fields = {}, type = this.type(), prototypes = type.field_prototypes;

			for (var i = 0, ii = this.content.fields.length; i < ii; i++) {
				console.log('field', this.content.fields[i].name, this.content.fields[i]);
				var f = this.content.fields[i], prototype, type_class;
				prototype = prototypes[f.name];
				if (f && prototype) {
					type_class = this.constantize(prototype.type);
					if (!type_class) {
						console.warn(
							"Content#fields:",
							"Field has invalid type", prototype.type,
							"content_id:", this.content.id,
							"type:", "'"+type.title+"'",
							"field_name:", f.name
						);
						type_class = Spontaneous.FieldTypes.StringField;
					}
					var field = new type_class(this, f);
					// field.watch('value', this.field_updated.bind(this, field));
					fields[f.name] = field;
				}
			};
			return fields;
		}.cache(),

		field: function(name) {
			return this.fields()[name];
		},
		field_updated: function(field, value) {
			this.save_field(field);
		},

		save_field: function(field) {
			var params = { field: {} };
			params.field[field.name] = {value: field.value()};
			Spontaneous.Ajax.post(this.save_path(), params, this.save_complete.bind(this));
		},

		save_path: function() {
			return ['/save', this.content.id].join('/');
		},

		save_complete: function(response) {
			if (response) {
				var fields = response.fields;
				for (var i = 0, ii = fields.length; i < ii; i++) {
					var values = fields[i], field = this.field(values.name);
					if (field) { field.update(values); }
				}
			}
		},

		has_fields: function() {
			return (this.content.fields.length > 0)
		},

		title: function() {
			return this.title_field().value();
		},

		title_field: function() {
			return this.fields()[this.type().title_field_name];
		},

		hidden: function() {
			return this.content.hidden;
		},

		entries: function() {
			if (!this.content.entries) {
				return [];
			}
			var _entries = [];
			for (var i = 0, ee = this.content.entries, ii = ee.length; i < ii; i++) {
				var entry = this.wrap_entry(ee[i]);
				_entries.push(entry);
			}
			return _entries;
		}.cache(),

		boxes: function() {
			var _boxes = [];
			if (this.content.boxes) {
				for (var i = 0, ee = this.content.boxes, ii = ee.length; i < ii; i++) {
					_boxes.push(new S.Box(ee[i], this));
				}
			}
			return _boxes;
		}.cache(),

		has_boxes: function() {
			return (this.boxes().length > 0)
		},

		wrap_entry: function(entry) {
			var entry_class = Spontaneous.Entry;
			if (entry.is_page) {
				entry_class = Spontaneous.PageEntry;
			}
			return new entry_class(entry, this);
		},

		allowed_types: function() {
			return this.type().allowed_types();
		},

		depth: function() {
			return this.content.depth;
		},

		destroy: function() {
			Spontaneous.Ajax.post(['/destroy', this.content.id].join('/'), {}, this.destroyed.bind(this));
		},
		toggle_visibility: function() {
			Spontaneous.Ajax.post(['/toggle', this.content.id].join('/'), {}, this.visibility_toggled.bind(this));
		},
		visibility_toggled: function(result) {
			console.log('visibility_toggled', result)
			this.set('hidden', result.hidden);
			// this.trigger('visibility_toggled', result);
		},
		destroyed: function() {
			var page = S.Editing.get('page');
			this.trigger('destroyed', this);
			page.trigger('removed_entry', this);
		},
		reposition: function(position) {
			Spontaneous.Ajax.post(['/content', this.content.id, 'position', position].join('/'), {}, function() {
				this.repositioned();
			}.bind(this));
		},
		repositioned: function() {
			this.trigger('repositioned');
		}
	});

	return Content;
}(jQuery, Spontaneous));
