console.log('Loading EditPanel...')

Spontaneous.EditPanel = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var EditPanel = new JS.Class(Dialogue, {
		initialize: function(content) {
			this.content = content;
		},
		buttons: function() {
			var save_label = "Save (" + ((window.navigator.platform.indexOf("Mac") === 0) ? "Cmd" : "Ctrl") + "+s)", btns = {};
			btns[save_label] = this.save.bind(this);
			return btns;
		},
		id: function() {
			return this.content.id();
		},
		uid: function() {
			return this.content.uid() + '!editing';
		},
		save: function() {
			var values = this.form.serializeArray();
			var field_data = new FormData();
			var size = 0;
			$.each(values, function(i, v) {
				field_data.append(v.name, v.value);
				size += (v.name.length + v.value.length);
			});
			$('> *', this.form).animate({'opacity': 0.3}, 400, function() {
				Spontaneous.UploadManager.form(this, field_data, size);
				$.each(this.content.file_fields(), function() {
					this.save();
				});
			}.bind(this));
			return false;
		},

		upload_progress: function(position, total) {
			console.log('EditPanel.upload_progress', position, total)
		},
		upload_complete: function(response) {
			var fields = response.fields;
			for (var i = 0, ii = fields.length; i < ii; i++) {
				var values = fields[i], field = this.content.field(values.name);
				field.update(values);
			}
			this.close();
		},
		cancel: function() {
			this.close();
			return false;
		},
		close: function() {
			S.Popover.close();

			var fields = this.content.field_list();
			for (var i = 0, ii = fields.length; i < ii; i++) {
				var field = fields[i];
				field.close_edit();
			}
			$(':input', this.form).add(document).unbind('keydown.savedialog');
			if (typeof this.content.edit_closed === 'function') {
				this.content.edit_closed();
			}
		},
		view: function() {
			var _save_ = this.save.bind(this);
			var _cancel_ = this.cancel.bind(this);
			var get_toolbar = function(class_name) {
				var save = $(dom.a, {'class':'save'}).text('Save').click(_save_);
				var cancel = $(dom.a, {'class':'cancel'}).text('Cancel').click(_cancel_);
				var toolbar = $(dom.div, {'class':'editing-toolbar'}).append(cancel).append(save);;
				if (class_name) { toolbar.addClass(class_name); }
				return toolbar;
			};
			var editing = $(dom.form, {'id':'editing-panel', 'enctype':'multipart/form-data', 'method':'post'});
			var toolbar = get_toolbar();
			var outer = $(dom.div);
			var text_field_wrap = $(dom.div, {'class':'field-group text'});
			var image_field_wrap = $(dom.div, {'class':'field-group image'});
			var text_fields = this.content.text_fields();
			var submit = $(dom.input, {'type':'submit'});
			editing.append(toolbar);
			for (var i = 0, ii = text_fields.length; i < ii; i++) {
				var field = text_fields[i];
				text_field_wrap.append(this.field_edit(field));
			}
			outer.append(text_field_wrap);
			var image_fields = this.content.image_fields();

			for (var i = 0, ii = image_fields.length; i < ii; i++) {
				var field = image_fields[i];
				image_field_wrap.append(this.field_edit(field));
			}
			outer.append(image_field_wrap);
			outer.append(submit);
			editing.append(outer);
			editing.append($(dom.div, {'class':'clear'}));
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
				var s_key = 83;
				if ((event.ctrlKey || event.metaKey) && event.keyCode === s_key) {
					this.save();
					return false;
				}
			}.bind(this));
			return this.form;
		},
		field_focus: function(input) {
			var text_fields = this.content.text_fields(), active_field = false;
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
			var d = $(dom.div, {'class':'field'});
			d.append($(dom.label, {'class':'name', 'for':field.css_id()}).html(field.label()));
			var toolbar = field.toolbar();
			if (toolbar) {
				d.append($(dom.div, {'class':'toolbar'}).html(toolbar));
			}
			var edit = field.edit();
			d.append($(dom.div, {'class':'value'}).html(edit));
			var footer = field.footer();
			if (footer) {
				d.append($(dom.div, {'class':'footer'}).html(footer));
			}
			return d;
		}
	});
	return EditPanel;
})(jQuery, Spontaneous);


