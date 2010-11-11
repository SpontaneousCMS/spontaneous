console.log('Loading EditDialogue...')

Spontaneous.EditDialogue = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var EditDialogue = new JS.Class(Dialogue, {
		initialize: function(content) {
			this.content = content;
			console.log('EditDialogue.new', content);
		},
		buttons: function() {
			return {
				'Save': this.save.bind(this)
			};
		},
		id: function() {
			return this.content.id();
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
			console.log('EditDialogue.upload_progress', position, total)
		},
		upload_complete: function(response) {
			var fields = response.fields;
			for (var i = 0, ii = fields.length; i < ii; i++) {
				var values = fields[i], field = this.content.field(values.name);
				field.update(values);
			}
			this.close();
		},
		body: function() {
			var editing = $(dom.form, {'id':'editing', 'enctype':'multipart/form-data', 'method':'post'});
			var outer = $(dom.div);
			outer.append($(dom.div, {'class':'field-group-bg text'}));
			outer.append($(dom.div, {'class':'field-group-bg image'}));
			var text_field_wrap = $(dom.div, {'class':'field-group text'});
			var image_field_wrap = $(dom.div, {'class':'field-group image'});
			var text_fields = this.content.text_fields();
			var submit = $(dom.input, {'type':'submit'});

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
			// activate the highlighting
			$('input, textarea', editing).focus(function() {
				$(this).parents('.field').first().addClass('focus');
			}).blur(function() {
				$(this).parents('.field').first().removeClass('focus');
			});
			editing.submit(this.save.bind(this));
			this.form = editing;
			return this.form;
		},
		field_edit: function(field) {
			var d = $(dom.div, {'class':'field'});
			d.append($(dom.label, {'class':'name', 'for':field.css_id()}).html(field.label()));
			var edit = field.edit();
			d.append($(dom.div, {'class':'value'}).html(edit));
			return d;
		}
	});
	return EditDialogue;
})(jQuery, Spontaneous);

