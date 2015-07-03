// console.log('Loading Content Area...')

Spontaneous.ContentArea = (function($, S) {
	var dom = S.Dom;
	var ContentArea = new JS.Singleton({
		include: Spontaneous.Properties,

		inner: null,
		preview: null,
		editing: null,
		mode: 'edit',

		init: function() {
			var self = this;
			self.wrap = dom.div('#content-outer');
			self.metaWrap = dom.div('#content-meta').hide();
			self.inner = dom.div('#content');
			self.inner.append(dom.div('#content-loading'));
			self.configureScrollBottomHandler(self.inner);
			self.preview = S.Preview.init(self.inner);
			self.editing = S.Editing.init(self.inner);
			self.service = S.Services.init(self.inner);
			self.wrap.append(self.metaWrap, self.inner);
			return self.wrap;
		},
		configureScrollBottomHandler: function(inner) {
			inner.scroll(function(contentArea, div) {
				var count = 0;
				return function(e) {
					var st = div.scrollTop()
					, ih = div.innerHeight()
					, sh = div[0].scrollHeight
					// don't wait until we're at the exact bottom, but trigger a little bit earlier
					// this should ideally be context sensitive, so that the trigger for short containers
					// loads a bit earlier. This would mean that the first load of additional content would
					// happen more promptly than later ones. Currently it's the inverse of that.
					, margin = 0.95
					, bottom = ((st + ih) >= (sh * margin));
					if (bottom) {
						contentArea.set('scroll_bottom', (++count));
					}
				};
			}(this, inner));
		},
		height: function() {
			return this.inner.height();
		},
		location_loading: function(destination) {
			if (destination) {
				this.wrap.addClass('loading');
				this.current().showLoading();
			} else {
				this.wrap.removeClass('loading');
				this.current().hideLoading();
			}
		},

		location_changed: function(location) {
			this.goto_page(location);
		},
		display: function(mode) {
			this.mode = mode;
			this.current().display(S.Location.location());
		},
		current: function() {
			var self = this, hide = [], active, editing = self.editing, service = self.service, preview = self.preview;
			self.exitMeta();

			if (self.mode === 'preview') {
				hide = [editing, service];
				active = preview;
			} else if (self.mode === 'edit') {
				hide = [preview, service];
				active = editing;
			} else if (self.mode === 'service') {
				hide = [preview, editing];
				active = service;
			}
			hide.forEach(function(el) { el.hide(); });
			active.show();
			return active;
		},
		goto_page: function(page) {
			this.current().goto_page(page);
		},
		scroll_to_bottom: function(duration, delay) {

			this.inner.delay(delay || 0).velocity({ scrollTop:this.inner[0].scrollHeight }, (duration || 1000));
		},
		showService: function(service) {
			if (!this.modeBeforeService) {
				this.modeBeforeService = this.mode;
			}
			this.mode = 'service';
			this.current().display(service.url);
		},
		hideService: function() {
			var mode = this.modeBeforeService;
			this.modeBeforeService = false;
			this.display(mode);
		},
		enterMeta: function(view) {
			if (this.metaView === view) { return; }
			this.metaView = view;
			var outer = this.metaWrap.hide();
			this.inner.velocity({top: '100%'}, 300, function() {
				if (view && typeof view.show === 'function') {
					view.show(outer);
				}
				outer.velocity('fadeIn', 300);
			});
		},
		exitMeta: function() {
			if (!this.metaView) { return; }
			if (typeof this.metaView.detach === 'function') {
				this.metaView.detach();
			}
			this.metaView = null;
			var inner = this.inner, outer = this.metaWrap;
			inner.velocity({top: '0%'}, 300, function() {
				outer.empty().hide();
			});
			outer.velocity('fadeOut', 300);
		}
	});
	return ContentArea;
})(jQuery, Spontaneous);

