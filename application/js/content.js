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
			Spontaneous.Ajax.post(this.save_path(), params, this, this.save_complete);
		},

		save_path: function() {
			return ['/save', this.content.id].join('/');
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
				if (this.content.boxes) {
					for (var i = 0, ee = this.content.boxes, ii = ee.length; i < ii; i++) {
						_boxes.push(ee[i]);
					}
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
		visibility_class: function() {
			return this.content.hidden ? 'hidden' : 'visible';
		},


		entry_added: function(result, callback) {
			console.log("Content.entry_added", result)
			var position = result.position, e = result.entry, entry = this.wrap_entry(e);
			this.content.entries.splice(position, 0, e);
			this._entries.splice(position, 0, entry);
			callback(entry, position);
		},

		destroy: function() {
			Spontaneous.Ajax.post(['/destroy', this.content.id].join('/'), {}, this, this.destroyed);
		},
		toggle_visibility: function() {
			Spontaneous.Ajax.post(['/toggle', this.content.id].join('/'), {}, this, this.visibility_toggled);
		},
		visibility_toggled: function(result) {
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
		// edit: function() {
		// 	return ;
		// 	// (new Spontaneous.EditDialogue(this)).open();
		// },
		//
		create_edit_wrapper: function(read_content) {
			var s = {'style':'position: relative; overflow: hidden;'}
			var outer = dom.div(s);
			var write = dom.div({'style':'position: absolute; height: 0; overflow: hidden;'})
			var write_inner = dom.div();
			var read = dom.div(s);
			var read_inner = dom.div();
			write.append(write_inner);
			read_inner.append(read_content);
			read.append(read_inner);
			outer.append(write).append(read);
			this.editing_area = {
				outer: outer,
				write: write,
				write_inner: write_inner,
				read: read,
				read_inner: read_inner
			};
			return outer;
		},

		edit: function() {
			var time_to_reveal = 300, back = 10, front = 20,
				a = this.editing_area, o = a.outer, w = a.write, r = a.read, wi = a.write_inner, ri = a.read_inner;
			var panel = new Spontaneous.EditPanel(this), view = panel.view();
			r.css('z-index', front);
			w.css('z-index', back).css('height', 'auto').show();
			wi.append(view);
			var h = wi.outerHeight();
			o.add(r).animate({'height':h}, { queue: false, duration: time_to_reveal });
			w.css({'position':'relative'});
			r.css({'position':'absolute', 'top':0, 'right':0, 'left':0}).animate({'top':h}, { queue: false, duration: time_to_reveal, complete:function() {
				w.css({'z-index': front, 'position':'relative', 'height':'auto'})
				r.css({'z-index': back, 'position':'absolute'})
				o.css('height', 'auto')
			}});
		},
		edit_closing: false,
		edit_closed: function() {
			if (this.edit_closing) { return; }
			this.edit_closing = true;
			var time_to_reveal = 300, back = 10, front = 20,
			  a = this.editing_area, o = a.outer, w = a.write, r = a.read, wi = a.write_inner, ri = a.read_inner,
				h = ri.outerHeight(), __content = this;
				o.add(r).animate({'height':h}, { queue: false, duration: time_to_reveal });
				r.css({'z-index':front, 'height':h, 'top':wi.outerHeight()+'px'}).animate({'top':0}, { queue: true, duration: time_to_reveal, complete: function() {
					w.css({'position':'absolute', 'z-index':back});
					r.css({'position':'relative', 'height':'auto', 'z-index':front})
					o.css('height', 'auto')
					wi.empty();
					__content.edit_closing = false;
				}});

		},
		save: function(dialogue, form_data) {
			// Spontaneous.Ajax.post('/'+this.model_name+'/'+this.id + '/save', $(form).serialize(), this, this.saved);
			console.log(form_data);
		}
	});

	return Content;
})(jQuery, Spontaneous);
