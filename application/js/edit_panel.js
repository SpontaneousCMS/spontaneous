// console.log('Loading EditPanel...')

Spontaneous.EditPanel = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var EditPanel = new JS.Class(Dialogue, {
		initialize: function(parent_view) {
			this.parent_view = parent_view;
		},
		buttons: function() {
			var save_label = "Save (" + ((window.navigator.platform.indexOf("Mac") === 0) ? "Cmd" : "Ctrl") + "+s)", btns = {};
			btns[save_label] = this.save.bind(this);
			return btns;
		},

		id: function() {
			return this.parent_view.id();
		},

		schema_id: function() {

		},

		uid: function() {
			return this.parent_view.uid() + '!editing';
		},

		save: function() {
			var fields = this.parent_view.field_list();
			console.log('save', fields)
			S.Ajax.test_field_versions(this.parent_view, fields, this.upload_values.bind(this), this.upload_conflict.bind(this));

			return false;
		},

		upload_values: function() {
			var values = this.form.serializeArray();
			var field_data = new FormData();
			var size = 0;
			$.each(values, function(i, v) {
				field_data.append(v.name, v.value);
				size += (v.name.length + v.value.length);
			});
			$('> *', this.form).animate({'opacity': 0.3}, 400);
			if (values.length > 0) {
				Spontaneous.UploadManager.form(this, field_data, size);
			} else {
				this.close();
			}
			$.each(this.parent_view.file_fields(), function() {
				this.save();
			});
		},

		save_path: function() {
			return this.parent_view.save_path();
		},

		upload_progress: function(position, total) {
			// console.log('EditPanel.upload_progress', position, total)
		},

		upload_complete: function(response) {
			this.parent_view.save_complete(response);
			this.close();
		},


		upload_failed: function(event) {
			// console.log("FAILED", event)
		},

		upload_conflict: function(conflict_data) {
			console.log('conflicted_fields', conflict_data)
			var dialogue = new S.ConflictedFieldDialogue(this, conflict_data);
			dialogue.open();
		},

		conflicts_resolved: function(conflict_list) {
			console.log('conflicts resolved', conflict_list)
			var ff = this.parent_view.field_list(), conflicts = {};
			for (var i =0, ii = conflict_list.length; i < ii; i++) {
				var conflict = conflict_list[i];
				conflicts[conflict.field.schema_id()] = conflict;
			}
			for (var i = 0, ii = ff.length; i < ii; i++) {
				var field = ff[i], conflict = conflicts[field.schema_id()];
				if (conflict) {
					console.log(">>> conflicts_resolved", field, conflict.version)
					field.set_edited_value(conflict.value);
					field.set_version(conflict.version);
				}
			}
			// no need to animate as the dialog is over the top
			// $('> *', this.form).css({'opacity': 1});
		},

		cancel: function() {
			var fields = this.parent_view.field_list();
			for (var i = 0, ii = fields.length; i < ii; i++) {
				fields[i].cancel_edit();
			}
			this.close();
			return false;
		},

		close: function() {
			S.Popover.close();

			var fields = this.parent_view.field_list();
			for (var i = 0, ii = fields.length; i < ii; i++) {
				fields[i].close_edit();
			}
			$(':input', this.form).add(document).unbind('keydown.savedialog');
			if (typeof this.parent_view.edit_closed === 'function') {
				this.parent_view.edit_closed();
			}
		},

		view: function() {
			var _save_ = this.save.bind(this);
			var _cancel_ = this.cancel.bind(this);
			var get_toolbar = function(class_name) {
				var save = dom.a('.button.save').html(dom.cmd_key_label('Save', 's')).click(_save_);
				var cancel = dom.a('.button.cancel').html(dom.key_label('Cancel', 'Esc')).click(_cancel_);
				var shadow = dom.div('.indent');
				var buttons = dom.div('.buttons').append(cancel).append(save);
				var toolbar = dom.div('.editing-toolbar').append(shadow).append(buttons);
				if (class_name) { toolbar.addClass(class_name); }
				return toolbar;
			};
			var editing = dom.form(['.editing-panel', this.parent_view.depth_class()], {'enctype':'multipart/form-data', 'method':'post'})
			var toolbar = get_toolbar();
			var outer = dom.div('.editing-fields');
			var text_field_wrap = dom.div('.field-group.text');
			var image_field_wrap = dom.div('.field-group.image');
			var text_fields = this.parent_view.text_fields();
			var submit = dom.input({'type':'submit'});
			editing.append(toolbar);
			for (var i = 0, ii = text_fields.length; i < ii; i++) {
				var field = text_fields[i];
				text_field_wrap.append(this.field_edit(field));
			}
			if (text_fields.length > 0) {
				outer.append(text_field_wrap);
			}
			var image_fields = this.parent_view.image_fields();

			for (var i = 0, ii = image_fields.length; i < ii; i++) {
				var field = image_fields[i];
				image_field_wrap.append(this.field_edit(field));
			}
			if (image_fields.length > 0) {
				outer.append(image_field_wrap);
			}
			outer.append(submit);
			editing.append(outer);
			editing.append(dom.div('.clear'));
			editing.append(get_toolbar('bottom'));
			__dialogue = this;
			// activate the highlighting
			$('input, textarea', editing).focus(function() {
				__dialogue.field_focus(this);
			}).blur(function() {
				// $(this).parents('.field').first().removeClass('focus');
			});
			editing.submit(this.save.bind(this));
			this.form = editing;
			$(':input', this.form).add(document).bind('keydown.savedialog', function(event) {
				var s_key = 83, esc_key = 27;
				if ((event.ctrlKey || event.metaKey) && event.keyCode === s_key) {
					this.save();
					return false;
				} else {
					if (event.keyCode === esc_key) {
						_cancel_();
					}
				}
			}.bind(this));
			return this.form;
		},
		on_show: function(focus_field) {
			if (!focus_field || !(focus_field['focus']) || !focus_field.accepts_focus) { focus_field = null; }
			var focus_field = focus_field || this.parent_view.text_fields()[0];
			if (focus_field) {
				focus_field.focus();
			}
		},
		field_focus: function(input) {
			var text_fields = this.parent_view.text_fields(), active_field = false;
			for (var i = 0, ii = text_fields.length; i < ii; i++) {
				var field = text_fields[i];
				if (field.input()[0] === input) {
					active_field = field;
					break;
				}
			}
			if (active_field === this.active_field) { return; }
			if (this.active_field) {
				this.active_field.on_blur();
			}
			if (active_field) {
				this.active_field = active_field;
				this.active_field.on_focus();
			}
		},
		field_edit: function(field) {
			var d = dom.div('.field');
			// d.append($(dom.label, {'class':'name', 'for':field.css_id()}).html(field.label()));
			var label = dom.label('.name', {'for':field.css_id()}).html(field.label());
			if (field.type.comment) {
			var comment = dom.span('.comment').text('('+field.type.comment+')');
			label.append(comment)
			}
			d.append(label);
			var toolbar = field.toolbar();
			if (toolbar) {
				d.append(dom.div('.toolbar').html(toolbar));
			}
			var edit = field.edit();
			d.append(dom.div('.value').append(edit));
			var footer = field.footer();
			if (footer) {
				d.append(dom.div('.footer').html(footer));
			}
			return d;
		}
	});
	return EditPanel;
})(jQuery, Spontaneous);


