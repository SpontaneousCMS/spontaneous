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
			this.iframe = $(dom.iframe, {"id":"preview_pane", src:S.Location.url()})
			this.iframe.hide();
			container.append(this.iframe);
			return this;
		},
		display: function(page) {
			this.iframe.fadeIn();
			this.iframe.bind('load.preview', function() {
				S.Preview.set({
					'title': this.contentWindow.document.title,
					'path': this.contentWindow.location.pathname
				});
				S.Location.load_path(this.contentWindow.location.pathname)
			});
			this.goto(page);
		},
		goto: function(page) {
			// if (!page || page.path == this.get('path')) { return; }
			this.iframe[0].contentWindow.location.href = page.path + click_param();
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


