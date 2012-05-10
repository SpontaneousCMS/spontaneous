// console.log('Loading DateField...')
Spontaneous.FieldTypes.WebVideoField = (function($, S) {
	var dom = S.Dom;
	var WebVideoField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		// get_input: function() {
		// 	this.input = $(dom.textarea, {'id':this.css_id(), 'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
		// 	return this.input;
		// },
		// edit: function() {
		// 	return this.get_input();
		// }
		preview: function() {
			var value = this.get('value')
			, iframe = dom.iframe({src:value, frameborder: 0, border: 0}).css({position: "absolute", top:0, left:0, height: "100%", width: "100%"});
			if (!value) { // don't fill up the page with empty iframes...
				return dom.div();
			}
			return dom.div().css({width: "100%", position: "relative", "padding-bottom":"56.25%", height: 0}).append(iframe)
		}
	});

	return WebVideoField;
})(jQuery, Spontaneous);
