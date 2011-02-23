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
			var location = Popover.div();
			var wrapper = $(dom.div, {'class':'pop-over'});
			var handle = $(dom.div, {'class':'menuHandle'});
			var header = $(dom.header).append(back_btn).append(title).css('width', this.view.width())
			var back_btn = $(dom.a, {'class':'button back black'}).append($(dom.span, {'class':'pointer'})).append($(dom.span, {'class':'label'}).text("Back")).hide();
			var title = $(dom.h3).text('Header from view');
			var close_btn = $(dom.a, {'class':'button close black'}).text('Close').click(this.close.bind(this));

			var view_wrapper = $(dom.div).css('width', this.view.width());
			view_wrapper.append(this.view.view());
			header.append(back_btn).append(title).append(close_btn);
			wrapper.append(handle).append(header).append(view_wrapper);
			var o = this.view.position_from_event(event);
			console.log(o)
			wrapper.offset({top:(o.top+18), left:(o.left - 24)});
			wrapper.hide();
			location.append(wrapper);
			this.wrapper = wrapper;
			wrapper.fadeIn(200);
		},
		close: function() {
			Popover.close();
			return false;
		},
		do_close: function() {
			// do actual element removal here
			this.view.before_close();
			this.view.do_close();
			this.view.after_close();
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
	return Popover;
})(jQuery, Spontaneous);


