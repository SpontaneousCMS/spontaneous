console.log("Loading PopoverView...");


Spontaneous.PopoverView = (function($, S) {
	var dom = S.Dom;
	var PopoverView = new JS.Class({
		initialize: function() {
			// should be over-ridden by subclasses
			// who should call #super
		},
		set_manager: function(manager) {
			this.manager = manager;
		},
		view: function() {
			// construct view
		},
		align: 'left',
		has_navigation: true,
		title: function() {
			return "Popover";
		},
		width: function() {
			return 400;
		},
		position_from_event: function(event) {
			return this.position_from_element(event);
		},
		position_from_element: function(event) {
			var t = $(event.currentTarget), o = t.offset();
			o.top += t.outerHeight();
			o.left += t.outerWidth() / 2;
			return o
		},
		position_from_mouse: function(event) {
			return {top: event.clientX, left: event.clientY};
		},
		after_open: function() {
		},
		close_text: function() {
			return 'Close';
		},
		close: function() {
			this.manager.close();
		},
		before_close: function() {
		},
		do_close: function() {
		},
		after_close: function() {
		}
	});
	return PopoverView;
})(jQuery, Spontaneous);



