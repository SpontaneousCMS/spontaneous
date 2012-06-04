// console.log('Loading Content Area...')

Spontaneous.ContentArea = (function($, S) {
	var dom = S.Dom;
	var ContentArea = new JS.Singleton({
		include: Spontaneous.Properties,

		wrap: null,
		preview: null,
		editing: null,
		mode: 'edit',

		init: function() {
			this.wrap = dom.div('#content');
			this.preview = S.Preview.init(this.wrap);
			this.editing = S.Editing.init(this.wrap);
			this.service = S.Services.init(this.wrap);
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

			this.wrap.delay(delay || 0).animate({ scrollTop:this.wrap[0].scrollHeight }, (duration || 1000));
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
		}
	});
	return ContentArea;
})(jQuery, Spontaneous);

