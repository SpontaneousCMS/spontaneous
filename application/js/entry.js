console.log('Loading Entry...')

Spontaneous.Entry = (function($, S) {
	var dom = S.Dom;
	var debug = 0;
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
			// wrapper.append(outline)
			inside.append(outline)
			if (this.depth() < 4) {
				// wrapper.append($(dom.div, {'class':'grey-bg'}));
				inside.append($(dom.div, {'class':'grey-bg'}));
			}
			wrapper.append(this.title_bar(wrapper));
			this.dialogue_box = $(dom.div, {'class':'dialogue', 'style':'display: none'});
			wrapper.append(this.dialogue_box);
			// wrapper.append(inside);
			var entry = $(dom.div, {'class':'entry'});
			var fields = new Spontaneous.FieldPreview(this, '');
			entry.append(fields.panel());
			// console.log("Entry#panel", this.entries())
			var box_container = new Spontaneous.BoxContainer(this);
			inside.append(entry);
			inside.append(box_container.panel());
			var preview_area = this.create_edit_wrapper(inside);
			wrapper.append(preview_area)
			this.wrapper = wrapper;
			this.outline = outline;
			// this.edit_wrapper = edit_wrapper;
			this.inside = inside;
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
			var d = this.dialogue_box;
			d.empty();
			var msg = $(dom.p, {'class':'message'}).text('Are you sure you want to delete this?');
			var btns = $(dom.div, {'class':'buttons'});
			var ok = $(dom.a, {'class':'default'}).text("Delete").click(function() {
				this.dialogue_box.slideUp(100, function() {
					this.wrapper.fadeTo(100, 0.5);
					this.destroy();
				}.bind(this));
				return false;
			}.bind(this))

			var cancel = $(dom.a).text("Cancel").click(function() {
				this.dialogue_box.slideUp();
				return false;
			}.bind(this));
			btns.append(ok).append(cancel);
			d.append(msg).append(btns);
			d.slideDown(200);
		},
		destroyed: function() {
			console.log('Entry.destroyed', this.content)
			this.wrapper.slideUp(200, function() {
				this.wrapper.remove();
			}.bind(this));
		}
	});
	return Entry;
})(jQuery, Spontaneous);
