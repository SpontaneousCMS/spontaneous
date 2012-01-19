// console.log('Loading LongStringField...')
Spontaneous.FieldTypes.LongStringField = (function($, S) {
	var dom = S.Dom;
	var LongStringField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		generate_input: function() {
			return dom.textarea(dom.id(this.css_id()), {'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
		}
	});

	return LongStringField;
})(jQuery, Spontaneous);

