console.log('Loading DOM...');

Spontaneous.Dom = (function($, S) {
	return {
		body: function() {
			return $(document.body);
		},
		div: "<div/>", p: "<p/>", iframe: "<iframe/>",
		a: "<a/>", select:'<select/>', option:'<option/>',
		ul: '<ul/>', li: '<li/>',
		dl: '<dl/>', dt: '<dt/>', dd: '<dd/>',
		table: '<table/>', tr: '<tr/>', td:'<td/>',
		h3: '<h3/>',
		input:'<input/>', button: '<button/>', form: '<form/>'
	};
})(jQuery, Spontaneous);

