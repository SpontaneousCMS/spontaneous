// console.log('Loading Entry...')

Spontaneous.Entry = (function($, S) {
	var dom = S.Dom, user = S.User;

	var Entry = new JS.Class(Spontaneous.Content, {
		initialize: function(content, container) {
			this.container = container;
			this.callSuper(content);
		}
	});
	return Entry;
})(jQuery, Spontaneous);
