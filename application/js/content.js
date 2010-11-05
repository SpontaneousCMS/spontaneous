console.log('Loading Content...')

Spontaneous.Content = (function($, S) {

	return {
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
		fields: function() {
			if (!this._fields) {
				var fields = {}, type = this.type(), prototypes = type.field_prototypes;

				for (var i = 0, ii = this.content.fields.length; i < ii; i++) {
					var f = this.content.fields[i],
						prototype = prototypes[f.name],
						type_class = this.constantize(prototype.type)
					if (!type_class) {
						console.warn(
							"Content#fields:", "Field has invalid type",
							"content_id:", this.content.id,
							"type:", "'"+type.title+"'",
							"field_name:", f.name
						);
						type_class = Spontaneous.FieldTypes.StringField;
					}
					var field = new type_class(this, f);
					field.add_listener('value', this.field_updated.bind(this, field));
					fields[f.name] = field;
				};
				this._fields = fields;
			}
			return this._fields;
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
					var entry = ee[i];//new Entry(ee[i]);
					// console.log("Content#entries", entry);
					var entry_class = Spontaneous.Entry;
					if (entry.is_page) { 
						entry_class = Spontaneous.PageEntry;
					}
					_entries.push(new entry_class(entry, this));
				}
				this._entries = _entries;
			}
			return this._entries;
		},
		allowed_types: function() {
			return this.type().allowed_types();
		},
		depth: function() {
			return this.content.depth;
		},
		depth_class: function() {
			return 'depth-'+this.depth();
		}
	};
})(jQuery, Spontaneous);
