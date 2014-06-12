// console.log('Loading DateField...')
Spontaneous.Field.WebVideo = (function($, S) {
	var dom = S.Dom;
	var WebVideoField = new JS.Class(Spontaneous.Field.String, {
		// get_input: function() {
		// 	this.input = $(dom.textarea, {'id':this.css_id(), 'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
		// 	return this.input;
		// },
		// edit: function() {
		// 	return this.get_input();
		// }
		preview: function() {
			// oh god. I need to have a UI only version of the player code which disables autoplay etc
			// at the moment the value passed to the ui is the same as the one used for templates
			// which, in the case of autoplay, is wildly inappropriate
			// at the same time I want to replace an immediately inserted video player with an
			// image + play button to reduce the impact of multiple videos on the cms ui load time
			var value = this.get('value').replace(/autoplay=1/, '')
			, iframe = dom.iframe({src:value, frameborder: 0, border: 0}).css({position: 'absolute', top:0, left:0, height: '100%', width: '100%'});
			if (!value) { // don't fill up the page with empty iframes...
				return dom.div();
			}
			return dom.div().css({width: '100%', position: 'relative', 'padding-bottom':'56.25%', height: 0}).append(iframe);
		}
	});

	return WebVideoField;
})(jQuery, Spontaneous);
