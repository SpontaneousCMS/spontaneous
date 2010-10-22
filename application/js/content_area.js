console.log('Loading Content Area...')

Spontaneous.ContentArea = (function($, S) {
	var dom = S.Dom;
	var content_area = $.extend({}, Spontaneous.Properties(), {
		wrap: null,
		preview: null,
		editing: null,
		mode: 'preview',

		init: function() {
			this.wrap = $(dom.div, {'id': 'content_area_wrap'})
			this.preview = S.Preview.init(this.wrap);
			this.editing = S.Editing.init(this.wrap);
			return this.wrap;
		},

		location_changed: function(location) {
			this.goto(location);
		},
		display: function(mode) {
			this.mode = mode;
			// this.wrap.find('> visible').hide();
			this.current().display(this.get('location'));
		},
		current: function() {
			if (this.mode === 'preview') {
				this.editing.hide();
				this.preview.show();
				return this.preview;
			} else if (this.mode === 'edit') {
				this.preview.hide();
				this.editing.show();
				return this.editing;
			}
		},
		goto: function(page) {
			// this.set('location', page);
			this.current().goto(page);
		}
	});
	return content_area;
})(jQuery, Spontaneous);

