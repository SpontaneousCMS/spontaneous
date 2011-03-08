console.log('Loading Entry...')

Spontaneous.Entry = (function($, S) {
	var dom = S.Dom;
	var debug = 0;
	var ConfirmDeletePopup = new JS.Class(Spontaneous.PopoverView, {
		initialize: function(entry) {
			this.entry = entry;
		},
		width: function() {
			return 208;
		},
		align: 'right',
		has_navigation: false,
		close_text: function() {
			return false;
		},
		title: function() {
			return "Delete this Piece?";
		},
		position_from_event: function(event) {
			return this.position_from_element(event);
		},
		view: function() {
			var __entry = this.entry;
			var w = $(dom.div, {'id':'popover-delete'}).click(function() {
				__entry.cancel_destroy();
				return false;
			});

			var ok = $(dom.a, {'class':'ok'}).text("Delete").click(function() {
				__entry.destroy();
				return false;
			});
			var cancel = $(dom.a, {'class':'cancel'}).text("Cancel");
			w.append(cancel, ok)
			return w;
		}
	});
	var Entry = new JS.Class(Spontaneous.Content, {
		initialize: function(content, container) {
			this.container = container;
			this.callSuper(content);
			// this.content = content;
			// console.log('FacetEntry#new', content, content.depth);
		},
		panel: function() {
			var wrapper = $(dom.div, {'class':['entry-wrap ', this.depth_class(), this.visibility_class()].join(' ')});
			var inside = $(dom.div, {'class':'entry-inner'});
			var outline = $(dom.div, {'class':'white-bg'}).mouseover(this.mouseover.bind(this)).mouseout(this.mouseout.bind(this)).click(this.edit.bind(this))
			inside.append(outline)
			if (this.depth() < 4) {
				inside.append($(dom.div, {'class':'grey-bg'}));
			}
			wrapper.append(this.title_bar(wrapper));
			// this.dialogue_box = $(dom.div, {'class':'dialogue', 'style':'display: none'});
			// wrapper.append(this.dialogue_box);
			var entry = $(dom.div, {'class':'entry'});
			var fields = new Spontaneous.FieldPreview(this, '');
			entry.append(fields.panel());
			var box_container = new Spontaneous.BoxContainer(this);
			inside.append(entry);
			inside.append(box_container.panel());
			var preview_area = this.create_edit_wrapper(inside);
			wrapper.append(preview_area)
			this.wrapper = wrapper;
			this.outline = outline;
			return wrapper;
		},

		title_bar: function(wrapper) {
			if (!this._title_bar) {
				var title_bar = $(dom.div, {'class':'title-bar'});
				var actions = $(dom.div, {'class':'actions', 'xstyle':'display: none'});
				var destroy = $(dom.a, {'class':'delete'});
				var visibility = $(dom.a, {'class':'visibility'});
				actions.append(destroy);
				actions.append(visibility);
				title_bar.append(actions);
				var _hide_pause;
				// wrapper.mouseenter(function() {
				// 	if (_hide_pause) { window.clearTimeout(_hide_pause); }
				// 	actions.slideDown(50);
				// }).mouseleave(function() {
				// 	_hide_pause = window.setTimeout(function() { actions.slideUp(100) }, 200);
				// });
				destroy.click(this.confirm_destroy.bind(this));
				visibility.click(this.toggle_visibility.bind(this));
				this._title_bar = title_bar;
			}
			return this._title_bar;
		},
		visibility_toggled: function(result) {
			this.wrapper.removeClass('visible hidden');
			if (result.hidden) {
				this.wrapper.switchClass('visible', 'hidden', 200);
			} else {
				this.wrapper.switchClass('hidden', 'visible', 200);
			}
		},
		mouseover: function() {
			this.outline.addClass('active');
		},
		mouseout: function() {
			this.outline.removeClass('active');
		},
		confirm_destroy: function() {
			if (this._dialogue && !this._dialogue.is_open) { this.close_destroy_dialogue(); }
			if (!this._dialogue) {
				this._dialogue = Spontaneous.Popover.open(event, new ConfirmDeletePopup(this));
			} else {
				this.close_destroy_dialogue();
			}
		},
		destroy: function() {
			this.close_destroy_dialogue();
			this.callSuper();
		},
		cancel_destroy: function() {
			this.close_destroy_dialogue();
		},
		close_destroy_dialogue: function() {
			if (this._dialogue) {
				this._dialogue.close();
				this._dialogue = null;
			}
		},
		destroyed: function() {
			this.wrapper.slideUp(200, function() {
				this.wrapper.remove();
			}.bind(this));
		}
	});
	return Entry;
})(jQuery, Spontaneous);
