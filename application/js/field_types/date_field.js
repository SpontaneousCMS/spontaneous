// console.log('Loading DateField...')
Spontaneous.FieldTypes.DateField = (function($, S) {
	var dom = S.Dom;
	var DateField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		// get_input: function() {
		// 	this.input = $(dom.textarea, {'id':this.css_id(), 'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
		// 	return this.input;
		// },
		// edit: function() {
		// 	return this.get_input();
		// }
	});

	return DateField;
})(jQuery, Spontaneous);

