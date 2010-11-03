console.log('Loading PageEntry...')

Spontaneous.PageEntry = (function($, S) {
	var dom = S.Dom;

	var PageEntry = function(content, container) {
		this.content = content;
		this.container = container;
	};
	PageEntry.prototype = $.extend({}, S.Entry.prototype, {
	});
	return PageEntry;
})(jQuery, Spontaneous);
