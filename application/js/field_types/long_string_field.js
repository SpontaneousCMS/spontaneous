// console.log('Loading LongStringField...')
Spontaneous.FieldTypes.LongStringField = (function($, S) {
	var dom = S.Dom;
	var LongStringField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		input: function() {
			if (!this._input) {
				this._input = dom.textarea(dom.id(this.css_id()), {'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
			}
			return this._input;
		}
	});

	return LongStringField;
})(jQuery, Spontaneous);

