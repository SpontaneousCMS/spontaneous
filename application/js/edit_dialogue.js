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
			var data = new FormData()
			$.each(values, function(i, v) {
				data.append(v.name, v.value);
			});
			Spontaneous.UploadManager.form(this, data);
			return false;
		},

		upload_progress: function(position, total) {
			console.log('EditDialogue.upload_progress', position, total)
		},
		upload_complete: function(response) {
			console.log('EditDialogue.upload_complete', response);
			this.close();
		},
		body: function() {
			var editing = $(dom.form, {'id':'editing', 'enctype':'multipart/form-data', 'method':'post'});
			editing.append($(dom.div, {'class':'field-group-bg text'}));
			editing.append($(dom.div, {'class':'field-group-bg image'}));
			var text_field_wrap = $(dom.div, {'class':'field-group text'});
			var image_field_wrap = $(dom.div, {'class':'field-group image'});
			var text_fields = this.content.text_fields();

			for (var i = 0, ii = text_fields.length; i < ii; i++) {
				var field = text_fields[i];
				text_field_wrap.append(this.field_edit(field));
			}
			editing.append(text_field_wrap);
			var image_fields = this.content.image_fields();

			for (var i = 0, ii = image_fields.length; i < ii; i++) {
				var field = image_fields[i];
				image_field_wrap.append(this.field_edit(field));
			}

			editing.append(image_field_wrap);
			// activate the highlighting
			$('input, textarea', editing).focus(function() {
				console.log('focus', this)
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

