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
			return 'Delete this ' + (this.parent_view.content.is_page() ? 'Page?' : 'Piece?');
		},
		position_from_event: function(event) {
			var p = this.callSuper();
			p.left = p.left - 3;
			return p;
		},
		view: function() {
			var __entry = this.parent_view;
			var w = dom.div('#popover-delete').click(function() {
				__entry.cancel_destroy();
				return false;
			});

			var ok = dom.a('.ok').text('Delete').click(function() {
				__entry.destroy();
				return false;
			});
			var cancel = dom.a('.cancel').text('Cancel');
			w.append(cancel, ok);
			return w;
		},
		scroll: true
	});

	var PieceView = new JS.Class(S.Views.View, {
		initialize: function(content, container_view) {
			this.callSuper(content);
			this.container_view = container_view;
		},
		panel: function() {
			var wrapper = dom.div(['entry-wrap', this.fields_class(), this.alias_class(), this.depth_class(), this.visibility_class(), this.boxes_class()]);
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

			if (!this.content.type().is_alias()) {
				contents.append(this.content_type_info());
			}
			contents.append(this.action_buttons(contents));
			if (this.content.type().is_alias()) {
				contents.append(this.alias_target_panel());
			}
			// this.dialogue_box = $(dom.div, {'class':'dialogue', 'style':'display: none'});
			// contents.append(this.dialogue_box);
			var entry = dom.div('.entry');
			var fields = new Spontaneous.FieldPreview(this, '', true);
			var fields_panel;
			if (fields.has_fields()) {
				fields_panel = fields.panel();
				entry.append(fields_panel);
			}
			var box_container = new Spontaneous.BoxContainer(this.content);
			inside.append(entry);
			inside.append(box_container.panel());
			var preview_area = this.create_edit_wrapper(inside);
			contents.append(preview_area);

			wrapper.append(contents, this.entry_spacer());
			this.wrapper = wrapper;
			this.outline = outline;
			this.fields_preview = fields_panel;
			return wrapper;
		},
		entry_spacer: function() {
			var entry_spacer = dom.div('.entry-spacer').hover(function() {
				this.container_view.show_add_after(this, entry_spacer);
			}.bind(this), function() {
				this.container_view.hide_add_after(this, entry_spacer);
			}.bind(this));
			return entry_spacer;
		},
		edit: function(focus_field) {
			if (!this.content.has_fields()) { return; }
			this.wrapper.addClass('editing');
			this.callSuper(focus_field);
		},
		edit_closed: function() {
			this.wrapper.removeClass('editing');
			this.callSuper();
		},
		alias_target_panel: function() {
			var content = this.content,
			click = function() { S.Location.load_id(content.target().page_id); },
			wrap = dom.div('.alias-target').click(click),
			icon = content.alias_icon,
			type = dom.span('.content-type').text(content.type().display_title(content));
			title = dom.a().html(content.content.alias_title);

			if (!content.has_fields()) { wrap.addClass('no-fields'); }

			if (icon) {
				var img = new Spontaneous.Image(icon);
				wrap.append(img.icon(60, 60).click(click));
			}

			return wrap.append(title, type);
		},
		content_type_info: function() {
			var type = dom.div('.content-type.piece').text(this.content.type().display_title(this.content));
			return type;
		},
		action_buttons: function(wrapper) {
			if (!this._action_buttons) {
				if (this.content.container.isWritable()) {
					// var label = user.is_developer() ? dom.a('.developer.source').attr('href', this.content.developer_edit_url()).text(this.content.developer_description()) : (this.content.type().title);
					var action_buttons = dom.div('.title-bar');//.append(label);
					var actions = dom.div('.actions');
					var destroy = dom.a('.delete');
					var visibility = dom.a('.visibility');
					actions.append(destroy);
					actions.append(visibility);
					action_buttons.append(actions);
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
					this._action_buttons = action_buttons;
				}
			}
			return this._action_buttons;
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
			if (!this.content.has_fields()) { return; }
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
		confirm_destroy: function(event) {
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
				this.trigger('removed', this);
			}.bind(this));
		}
	});
	PieceView.ConfirmDeletePopup = ConfirmDeletePopup;
	return PieceView;
}(jQuery, Spontaneous));

