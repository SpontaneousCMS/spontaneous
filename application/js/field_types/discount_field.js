console.log('Loading DiscountField...')
Spontaneous.FieldTypes.DiscountField = (function($, S) {
	var dom = S.Dom;
	var DiscountField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		get_input: function() {
			this.input = $(dom.textarea, {'id':this.css_id(), 'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
			return this.input;
		},
		edit: function() {
			return this.get_input();
		}
	});

	return DiscountField;
})(jQuery, Spontaneous);

