// console.log('Loading Preview...');

Spontaneous.Preview = (function($, S) {
	var dom = S.Dom, goto_id = 0;
	var click_param = function() {
		return "?__click="+(++goto_id);
	};
	var Preview = new JS.Singleton({
		include: Spontaneous.Properties,

		element: function() {
			return wrap;
		},

		title: function() {
			return this.get('title') || "";
		},
		init: function(container) {
			this.iframe = dom.iframe("#preview_pane", {'src':'about:blank'})
			this.iframe.hide();
			container.append(this.iframe);
			return this;
		},
		display: function(page) {

			// HACK: must be a better way of making sure that updates to the path are
			// propagated throughout entrie interface
			var path = S.Location.get('path');
			// console.log('display', page)
			// console.log('>>> path', S.Location.get('path'))
			this.iframe.show().fadeOut(0)
			this.iframe.bind('load.preview', function() {
				var _iframe = this;
				$(this.contentWindow.document).ready(function() {
					$(_iframe).fadeIn(100);
				})
				S.Preview.set({
					'title': this.contentWindow.document.title,
					'path': this.contentWindow.location.pathname
				});
				S.Location.load_path(this.contentWindow.location.pathname)
			});
			this.goto_path(path);
		},
		goto_path: function(path) {
			if (path) {
				path += click_param();
				this.iframe[0].contentWindow.location.href = path;
			}
		},
		goto_page: function(page) {
			if (page) {
				this.goto_path(page.path);
			}
		},
		hide: function() {
			this.iframe.unbind('load.preview').hide();
		},
		show: function() {
			this.iframe.show();
		}
	});
	return Preview;
})(jQuery, Spontaneous);
