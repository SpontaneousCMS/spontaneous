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
		allowed_types: function() {
			return this.type().allowed_types();
		}
	};
})(jQuery, Spontaneous);
