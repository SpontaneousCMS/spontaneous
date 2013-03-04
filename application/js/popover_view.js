// console.log("Loading PopoverView...");


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
		position_from_event: function(target) {
			var p = this.position_from_element(target);
			// need to subtract the height of the top-bar because the
			// popover is positioned absolutely inside the data-pane but
			// given coordinates relative to the body
			p.top = p.top + 18 - 37 - this.attach_to().scrollTop();
			return p;
		},
		position_from_element: function(t) {
			var t = $(t), o = this.element_position(t);
			o.top += t.outerHeight();
			o.left += t.outerWidth() / 2;
			return o
		},
		element_position: function(el) {
			return $(el).offset();
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
		},
		attach_to: function() {
			return Spontaneous.Popover.div();
		},
		// Should the popover scroll with the document?
		scroll: false,
		scroll_element: function() {
			return S.ContentArea.inner;
		}
	});
	return PopoverView;
})(jQuery, Spontaneous);



