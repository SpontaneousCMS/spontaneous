console.log('Loading Content...')

Spontaneous.Content = (function($, S) {

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
		type: function() {
			if (!this._type) {
				this._type = S.Types.type(this.content.type);
			}
			return this._type;
		},

		constantize: function(type) {
			var parts = type.split(/\./), obj = window;
			for (var i = 0, ii = parts.length; i < ii; i++) {
				obj = obj[parts[i]];
			}
			return obj;
		},

		unload: function() {
			// console.log('Content.unload', this.uid());
			$.each(this.field_list(), function(i, f) { f.unload(); });
			$.each(this.entries(), function(i, e) { e.unload(); });
		},
		field_list: function() {
			if (!this._field_list) {

			var type = this.type(), prototypes = type.field_prototypes, names = type.field_names;
			var fields = this.fields(), list = [];
				for (var i = 0, ii = names.length; i < ii; i++) {
					list.push(fields[names[i]]);
				}
				this._field_list = list;
			}
			return this._field_list;
		},
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
			if (!this._fields) {
				console.log("Content.fields", this.type())
				var fields = {}, type = this.type(), prototypes = type.field_prototypes;

				for (var i = 0, ii = this.content.fields.length; i < ii; i++) {
					var f = this.content.fields[i],
						prototype = prototypes[f.name],
						type_class = this.constantize(prototype.type)
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
					// field.add_listener('value', this.field_updated.bind(this, field));
					fields[f.name] = field;
				};
				this._fields = fields;
			}
			return this._fields;
		},
		field: function(name) {
			return this.fields()[name];
		},
		field_updated: function(field, value) {
			this.save_field(field);
		},

		save_field: function(field) {
			var params = { field: {} };
			params.field[field.name] = {value: field.value()};
			Spontaneous.Ajax.post('/save/'+this.content.id, params, this, this.save_complete);
		},

		save_complete: function() {
		},

		has_fields: function() {
			return (this.content.fields.length > 0)
		},

		entries: function() {
			if (!this.content.entries) {
				return [];
			}
			if (!this._entries) {
				var _entries = [];
				for (var i = 0, ee = this.content.entries, ii = ee.length; i < ii; i++) {
					_entries.push(this.wrap_entry(ee[i]));
				}
				this._entries = _entries;
			}
			return this._entries;
		},

		boxes: function() {
			if (!this._boxes) {
				var _boxes = [];
				for (var i = 0, ee = this.content.boxes, ii = ee.length; i < ii; i++) {
					_boxes.push(ee[i]);
				}
				this._boxes = _boxes;
			}
			return this._boxes;
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

		depth_class: function() {
			return 'depth-'+this.depth();
		},

		add_entry: function(type, position, callback) {
			console.log('Content.add_entry', this.content, type.type, position);
			Spontaneous.Ajax.post(['/add', this.content.id, type.type].join('/'), {}, this, function(result) {
				this.entry_added(result, callback);
			});
		},

		entry_added: function(result, callback) {
			console.log("Content.entry_added", result)
			var position = result.position, e = result.entry, entry = this.wrap_entry(e);
			this.content.entries.splice(position, 0, e);
			this._entries.splice(position, 0, entry);
			callback(entry, position);
		},

		destroy: function() {
			console.log('Content.destroy', this.content.id);
			Spontaneous.Ajax.post(['/destroy', this.content.id].join('/'), {}, this, this.destroyed);
		},
		destroyed: function() {

		},
		reposition: function(position, callback) {
			Spontaneous.Ajax.post(['/content', this.content.id, 'position', position].join('/'), {}, this, function() {
				this.repositioned(callback);
			}.bind(this));
		},
		repositioned: function(callback) {
			if (typeof callback === 'function') {
				callback(this);
			}
		},
		edit: function() {
			console.log('Content.edit', this.content);
			(new Spontaneous.EditDialogue(this)).open();
		},
		save: function(dialogue, form_data) {
			// Spontaneous.Ajax.post('/'+this.model_name+'/'+this.id + '/save', $(form).serialize(), this, this.saved);
			console.log(form_data);
		}
	});

	return Content;
})(jQuery, Spontaneous);
