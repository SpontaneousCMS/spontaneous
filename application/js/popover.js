// console.log("Loading Popover...");


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
			var location = view.attach_to();
			var wrapper = dom.div('.pop-over');
			var handle = dom.div('.menuHandle');
			var header = dom.header();//.append(back_btn).append(title);
			var title = dom.h3().text(view.title());

			var view_wrapper = dom.div().css('width', view.width());
			view_wrapper.append(view.view());

			if (view.has_navigation) {
				var back_btn = dom.a('.button.back').append(dom.span('.pointer')).append(dom.span('.label').text("Back")).css('visibility', 'hidden');
				header.append(back_btn);
			}
			var target = event.currentTarget;
			this.set_position(target, wrapper, handle);

			header.append(title);

			if (view.close_text()) {
				var close_btn = dom.a('.button.close').text(view.close_text()).click(this.close.bind(this));
				header.append(close_btn);
			}
			wrapper.append(handle).append(header).append(view_wrapper);
			wrapper.hide();
			location.append(wrapper);

			var update_position = function(e) {
				this.set_position(target, wrapper, handle);
			}.bind(this);

			if (view.scroll) {
				view.scroll_element().bind("scroll.popover", update_position);
			}
			this.wrapper = wrapper;
			this.is_open = true;
			wrapper.fadeIn(200, this.after_open.bind(this));
		},

		set_position: function(target, wrapper, handle) {
			var view = this.view, o = view.position_from_event(target), handle_width = 30, offset = 10, left = -30, top = 18;

			if (view.align === 'right') {
				handle.css('left', (view.width() - (offset + handle_width)) + 'px')
				left = -(view.width() - (offset + handle_width/2) + 8);
			}
			wrapper.css({top:(o.top), left:(o.left + left)});
		},

		after_open: function() {
			this.view.after_open();
		},
		close: function() {
			var view = this.view;
			if (view.scroll) {
				view.scroll_element().unbind("scroll.popover");
			}
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
			if (!this._div) { this._div = $('#content-outer'); }
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


