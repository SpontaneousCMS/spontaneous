console.log('Loading Preview...');

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
			this.iframe = $(dom.iframe, {"id":"preview_pane", src:'about:blank'})
			this.iframe.hide();
			container.append(this.iframe);
			return this;
		},
		display: function(page) {
			console.log('display', page)
			this.iframe.show().fadeOut(0)
			this.iframe.bind('load.preview', function() {
				var _iframe = this;
				$(this.contentWindow.document).ready(function() {
					$(_iframe).fadeIn(100);
				})
				console.log('iframe.load', this.contentWindow.location.pathname);
				S.Preview.set({
					'title': this.contentWindow.document.title,
					'path': this.contentWindow.location.pathname
				});
				S.Location.load_path(this.contentWindow.location.pathname)
			});
			this.goto(page);
		},
		goto: function(page) {
			if (page) {
				var path = page.path + click_param();
				// console.log('goto', path)
				this.iframe[0].contentWindow.location.href = path;
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


