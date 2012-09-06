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
			this.wrap  = dom.div("#content-outer");
			this.metaWrap = dom.div("#content-meta").hide();
			this.inner = dom.div('#content');
			this.preview = S.Preview.init(this.inner);
			this.editing = S.Editing.init(this.inner);
			this.service = S.Services.init(this.inner);
			this.wrap.append(this.metaWrap, this.inner);
			return this.wrap;
		},

		location_changed: function(location) {
			this.goto_page(location);
		},
		display: function(mode) {
			this.mode = mode;
			this.current().display(S.Location.location());
		},
		current: function() {
			this.exitMeta();
			// YUK
			if (this.mode === 'preview') {
				this.editing.hide();
				this.service.hide();
				this.preview.show();
				return this.preview;
			} else if (this.mode === 'edit') {
				this.preview.hide();
				this.service.hide();
				this.editing.show();
				return this.editing;
			} else if (this.mode === 'service') {
				this.preview.hide();
				this.editing.hide();
				this.service.show();
				return this.service;
			}
		},
		goto_page: function(page) {
			this.current().goto_page(page);
		},
		scroll_to_bottom: function(duration, delay) {

			this.inner.delay(delay || 0).animate({ scrollTop:this.inner[0].scrollHeight }, (duration || 1000));
		},
		showService: function(service) {
			if (!this.modeBeforeService) {
				this.modeBeforeService = this.mode;
			}
			this.mode = "service";
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
			this.inner.animate({top: "100%"}, 300, function() {
				if (view && typeof view.show === "function") {
					view.show(outer);
				}
				outer.fadeIn(300);
			});
		},
		exitMeta: function() {
			if (!this.metaView) { return; }
			if (typeof this.metaView.detach === "function") {
				this.metaView.detach();
			}
			this.metaView = null;
			var inner = this.inner, outer = this.metaWrap;
			inner.animate({top: "0%"}, 300, function() {
				outer.empty().hide();
			});
			outer.fadeOut(300);
		}
	});
	return ContentArea;
})(jQuery, Spontaneous);

