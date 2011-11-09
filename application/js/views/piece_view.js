// console.log('Loading PieceView...')

Spontaneous.Views.PieceView = (function($, S) {
	var dom = S.Dom, user = S.User;
	var debug = 0;

	var ConfirmDeletePopup = new JS.Class(Spontaneous.PopoverView, {
		initialize: function(parent_view) {
			this.parent_view = parent_view;
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
			return "Delete this " + (this.parent_view.content.is_page() ? "Page?" : "Piece?");
		},
		position_from_event: function(event) {
			return this.position_from_element(event);
		},
		view: function() {
			var __entry = this.parent_view;
			var w = dom.div('#popover-delete').click(function() {
				__entry.cancel_destroy();
				return false;
			});

			var ok = dom.a('.ok').text("Delete").click(function() {
				__entry.destroy();
				return false;
			});
			var cancel = dom.a('.cancel').text("Cancel");
			w.append(cancel, ok)
			return w;
		}
	});

	var PieceView = new JS.Class(S.Views.View, {
		initialize: function(content, container) {
			this.callSuper(content);
			this.container = container;
		},
		panel: function() {
			var wrapper = dom.div(['entry-wrap', this.depth_class(), this.visibility_class(), this.boxes_class()])
			var contents = dom.div('.entry-contents');
			var inside = dom.div('.entry-inner');
			var outline = dom.div('.white-bg').
				mouseover(this.mouseover.bind(this)).
				mouseout(this.mouseout.bind(this)).
				click(this.edit.bind(this));
			inside.append(outline);
			if (this.content.depth() < 4) {
				inside.append(dom.div('.grey-bg'));
			}

			contents.append(this.title_bar(contents));
			if (this.content.type().is_alias()) {
				contents.append(this.alias_target_panel());
			}
			// this.dialogue_box = $(dom.div, {'class':'dialogue', 'style':'display: none'});
			// contents.append(this.dialogue_box);
			var entry = dom.div('.entry');
			var fields = new Spontaneous.FieldPreview(this, '');
			if (fields.has_fields()) {
				var fields_panel = fields.panel();
				entry.append(fields_panel);
			}
			var box_container = new Spontaneous.BoxContainer(this.content);
			inside.append(entry);
			inside.append(box_container.panel());
			var preview_area = this.create_edit_wrapper(inside);
			contents.append(preview_area);
			wrapper.append(contents, dom.div('.entry-spacer'));
			this.wrapper = wrapper;
			this.outline = outline;
			this.fields_preview = fields_panel;
			return wrapper;
		},
		edit: function(focus_field) {
			this.wrapper.addClass('editing')
			this.callSuper(focus_field);
		},
		edit_closed: function() {
			this.wrapper.removeClass('editing');
			this.callSuper();
		},
		alias_target_panel: function() {
			var content = this.content,
			wrap = dom.div('.alias-target'),
			icon = content.alias_icon,
			click = function() { S.Location.load_id(content.target().id); },
			title = dom.a().html(content.content.alias_title).click(click);


			if (icon) {
				var img = new Spontaneous.Image(icon);
				wrap.append(img.icon(60, 60).click(click))
			}

			return wrap.append(title)
		},
		title_bar: function(wrapper) {
			if (!this._title_bar) {
				var label = user.is_developer() ? dom.a('.developer.source').attr('href', this.content.developer_edit_url()).text(this.content.developer_description()) : (this.content.type().title);
				var title_bar = dom.div('.title-bar')//.append(label);
				var actions = dom.div('.actions', {'xstyle':'display: none'});
				var destroy = dom.a('.delete');
				var visibility = dom.a('.visibility');
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
				this.content.watch('hidden', this.visibility_changed.bind(this));
				visibility.click(this.toggle_visibility.bind(this));
				this._title_bar = title_bar;
			}
			return this._title_bar;
		},
		reposition: function(position, callback) {
			this.content.bind('repositioned', callback);
			this.content.reposition(position);
		},
		toggle_visibility: function() {
			this.content.toggle_visibility();
		},
		visibility_changed: function(hidden) {
			var duration = 200;
			this.wrapper.removeClass('visible hidden');
			if (hidden) {
				this.wrapper.switchClass('visible', 'hidden', duration);
			} else {
				this.wrapper.switchClass('hidden', 'visible', duration);
			}
		},
		mouseover: function() {
			this.outline.addClass('active');
			if (this.fields_preview) {
				this.fields_preview.addClass('hover');
			}
		},
		mouseout: function() {
			this.outline.removeClass('active');
			if (this.fields_preview) {
				this.fields_preview.removeClass('hover');
			}
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
			this.content.bind('destroyed', this.destroyed.bind(this));
			this.content.destroy();
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
			this.wrapper.disappear(function() {
				this.wrapper.remove();
			}.bind(this));
		}
	});
	return PieceView;
}(jQuery, Spontaneous));

