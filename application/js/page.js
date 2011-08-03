// console.log('Loading Page...')

Spontaneous.Page = (function($, S) {
	var dom = S.Dom, user = S.User;

	var Page = new JS.Class(Spontaneous.Content, {
		initialize: function(content) {
			this.callSuper(content);
			this.set('path', content.path);
		},

		save_complete: function(values) {
			this.callSuper(values)
			this.set('slug', values.slug);
			this.set('path', values.path);
		},
		depth: function() {
			// depth in this case refers to content depth which is always 0 for pages
			return 0;
		}
	});

	return Page;
}(jQuery, Spontaneous));
