// console.log('Loading DOM...');

Spontaneous.Dom = (function($, S) {
	return {
		body: function() {
			return $(document.body);
		},
		div: "<div/>", p: "<p/>", iframe: "<iframe/>",
		a: "<a/>", span: "<span/>", img: '<img/>',
		select:'<select/>', option:'<option/>', label:'<label/>',
		ul: '<ul/>', li: '<li/>',
		dl: '<dl/>', dt: '<dt/>', dd: '<dd/>',
		table: '<table/>', tr: '<tr/>', td:'<td/>',
		h3: '<h3/>', header: '<header/>',
		input:'<input/>', button: '<button/>', form: '<form/>',
		textarea:'<textarea/>'
	};
})(jQuery, Spontaneous);

