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
			var header = $(dom.header);//.append(back_btn).append(title);
			var title = $(dom.h3).text(view.title());

			var view_wrapper = $(dom.div).css('width', view.width());
			view_wrapper.append(view.view());

			if (view.has_navigation) {
				var back_btn = $(dom.a, {'class':'button back'}).append($(dom.span, {'class':'pointer'})).append($(dom.span, {'class':'label'}).text("Back")).css('visibility', 'hidden');
				header.append(back_btn);
			}
			header.append(title);
			if (view.close_text()) {
				var close_btn = $(dom.a, {'class':'button close'}).text(view.close_text()).click(this.close.bind(this));
				header.append(close_btn);
			}
			wrapper.append(handle).append(header).append(view_wrapper);
			var o = view.position_from_event(event), handle_width = 30, offset = 10, left = -30, top = 18;

			if (view.align === 'right') {
				handle.css('left', (view.width() - (offset + handle_width)) + 'px')
				left = -(view.width() - (offset + handle_width/2) + 8);
			}
			// need to subtract the height of the top-bar because the
			// popover is positioned absolutely inside the data-pane but
			// given coordinates relative to the body
			top -= 31 - Popover.div().scrollTop();
			wrapper.offset({top:(o.top+top), left:(o.left + left)});
			wrapper.hide();
			location.append(wrapper);
			this.wrapper = wrapper;
			this.is_open = true;
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
			this.is_open = false;
			this.wrapper.fadeOut(100, function() {
				$(this).remove();
			});
		}
	});
	Popover.extend({
		_instance: false,
		div: function() {
			if (!this._div) { this._div = $('#content'); }
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


