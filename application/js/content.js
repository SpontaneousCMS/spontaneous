console.log('Loading Content...')

Spontaneous.Content = (function($, S) {

	return {
		type: function() {
			if (!this._type) {
				this._type = S.Types.type(this.content.type);
			}
			return this._type;
		},
		fields: function() {
			if (!this._fields) {
				var fields = {};
				for (var i = 0, ii = this.content.fields.length; i < ii; i++) {
					var f = this.content.fields[i];
					fields[f.name] = new Spontaneous.FieldTypes.StringField(this, f);
				};
				this._fields = fields;
			}
			return this._fields;
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
					console.log("Content#entries", entry);
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
		}
	};
})(jQuery, Spontaneous);
