// console.log('Loading Preview...');

Spontaneous.Preview = (function($, S, $window) {
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
			// propagated throughout entire interface
			var path = S.Location.get('path');
			var preview = this, $iframe = this.iframe, iframe = $iframe[0];
			var location, monitorInterval = 200, monitor = function() {
				var icw = iframe.contentWindow, currentLocation = icw.location.pathname;
				if (currentLocation !== location) {
					location = currentLocation;
					S.Preview.set({
						'title': iframe.contentWindow.document.title,
						'path': iframe.contentWindow.location.pathname
					});
					$(icw).bind('unload', function(e) {
						// trigger a progress indicator here
					});
					S.Location.load_path(iframe.contentWindow.location.pathname);
				}
			};

			$iframe.hide();
			$iframe.one("load", function() {
				$iframe.show();
				if (!preview.previewPathMonitor) {
					preview.previewPathMonitor = $window.setInterval(monitor, monitorInterval);
				}
			});
			this.goto_path(path);
		},
		goto_path: function(path) {
			if (path) {
				// path += click_param();
				this.iframe[0].contentWindow.location.href = path;
			}
		},
		goto_page: function(page) {
			var current = this.get('path');
			if (!current || (page && (page.path !== current))) {
				this.goto_path(page.path);
			}
		},
		hide: function() {
			var preview = this;
			preview.iframe.unbind('load.preview').hide();
			if (preview.previewPathMonitor) {
				$window.clearInterval(preview.previewPathMonitor);
				preview.previewPathMonitor = null;
			}
		},
		show: function() {
			this.iframe.show();
		},
		showLoading: function() {
			// best to just ignore this message
		},
		hideLoading: function() {
			// best to just ignore this message
		}
	});
	return Preview;
})(jQuery, Spontaneous, window);
