console.log("Loading Popover...");


Spontaneous.Popover = (function($, S) {
	var dom = S.Dom;
	var __popover_id = 0;
	var Popover = new JS.Class({
		initialize: function(view) {
			this.id = (++__popover_id);
			this.view = view;
			this.view.set_manager(this);
			this.depth = 0;
		},
		open: function(event) {
			var view = this.view;
			var location = Popover.div();
			var wrapper = $(dom.div, {'class':'pop-over'});
			var handle = $(dom.div, {'class':'menuHandle'});
			var header = $(dom.header).append(back_btn).append(title);
			var back_btn = $(dom.a, {'class':'button back'}).append($(dom.span, {'class':'pointer'})).append($(dom.span, {'class':'label'}).text("Back")).css('visibility', 'hidden');
			var title = $(dom.h3).text(view.title());
			var close_btn = $(dom.a, {'class':'button close'}).text(view.close_text()).click(this.close.bind(this));

			var view_wrapper = $(dom.div).css('width', view.width());
			view_wrapper.append(view.view());
			header.append(back_btn).append(title).append(close_btn);
			wrapper.append(handle).append(header).append(view_wrapper);
			var o = view.position_from_event(event);
			console.log(o)
			wrapper.offset({top:(o.top+18), left:(o.left - 30)});
			wrapper.hide();
			location.append(wrapper);
			this.wrapper = wrapper;
			wrapper.fadeIn(200, this.after_open.bind(this));
		},
		after_open: function() {
			this.view.after_open();
		},
		close: function() {
			Popover.close();
			return false;
		},
		do_close: function() {
			var view = this.view;
			// do actual element removal here
			view.before_close();
			view.do_close();
			view.after_close();
			this.wrapper.fadeOut(100, function() {
				$(this).remove();
			});
		}
	});
	Popover.extend({
		_instance: false,
		div: function() {
			if (!this._div) { this._div = $('body'); }
			return this._div;
		},
		open: function(event, view) {
			this.close();
			this._instance = new Popover(view);
			this._instance.open(event);
			return this._instance;
		},
		close: function() {
			if (this._instance) {
				this._instance.do_close();
				this._instance = null;
			}
		}
	});
	$(document).bind('keydown.popover', function(event) {
		if (event.keyCode === 27) {
			Popover.close();
		}
	})
	return Popover;
})(jQuery, Spontaneous);


