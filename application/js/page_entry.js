// console.log('Loading PageEntry...')

Spontaneous.PageEntry = (function($, S) {
	var PageEntry = new JS.Class(Spontaneous.Content, {
		save_complete: function(values) {
			var _this = this;
			_this.callSuper(values)
			_this.set('slug', values.slug);
			_this.set('path', values.path);
		}
	});
	return PageEntry;
})(jQuery, Spontaneous);
