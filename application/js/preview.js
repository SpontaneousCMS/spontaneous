// console.log('Loading Preview...');

Spontaneous.Preview = (function($, S, $window) {
	var dom = S.Dom, goto_id = 0, Ajax = S.Ajax;
	var click_param = function() {
		return '?__click='+(++goto_id);
	};
	var Preview = new JS.Singleton({
		include: Spontaneous.Properties,

		element: function() {
			return wrap;
		},

		title: function() {
			return this.get('title') || '';
		},
		init: function(container) {
			this.iframe = dom.iframe('#preview_pane', {'src':'about:blank'});
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
						'title': icw.document.title,
						'path': icw.location.pathname
					});
					$(icw).bind('unload', function(e) {
						// trigger a progress indicator here
					});
					// don't load the page details into the top-bar if we're viewing a private page
					if (preview.pathIsPublic(icw.location.pathname)) {
						S.Location.load_path(icw.location.pathname);
					}
				}
			};

			$iframe.hide();
			$iframe.one('load', function() {
				$iframe.show();
				if (!preview.previewPathMonitor) {
					preview.previewPathMonitor = $window.setInterval(monitor, monitorInterval);
				}
			});
			this._goto_page(page, path)
		},
		pathIsPublic: function(path) {
			return (path.indexOf([Ajax.namespace, 'private'].join('/')) === -1)
		},
		goto_path: function(path) {
			if (path) {
				// path += click_param();
				this.load_url(path);
			}
		},
		goto_private: function(page) {
			if (page) {
				this.load_url([Ajax.namespace, 'private', page.id].join('/'));
			}
		},
		load_url: function(url) {
				this.iframe[0].contentWindow.location.href = url;
		},
		goto_page: function(page) {
			var current = this.get('path');
			if (!current || (page && (page.path !== current))) {
				this._goto_page(page, page.path)
			}
		},
		_goto_page: function(page, path) {
			if (page && page.private) {
				this.goto_private(page);
			} else {
				this.goto_path(path);
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
