// console.log('Loading FileField...')
Spontaneous.FieldTypes.FileField = (function($, S) {
	var dom = S.Dom;
	var FileField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		selected_files: false,
		preview: function() {
			Spontaneous.UploadManager.register(this);
			return this.callSuper();
		},
		unload: function() {
			this.callSuper();
			this.input = null;
			this._progress_bar = null;
			Spontaneous.UploadManager.unregister(this);
		},
		upload_complete: function(values) {
			console.log('FileField#upload_complete', values)
			this.set('value', values.processed_value);
			this.set_version(values.version);
			this.selected_files = null;
			this.disable_progress();
		},
		disable_progress: function() {
			this.progress_bar().parent().hide();
			this.drop_target.removeClass('uploading')
		},
		upload_progress: function(position, total) {
			if (!this.drop_target.hasClass('uploading')) { this.drop_target.addClass('uploading'); }
			this.progress_bar().parent().show();
			this.progress_bar().css('width', ((position/total)*100) + '%');
		},
		is_file: function() {
			return true;
		},
		get_input: function() {
			this.input = dom.input({'type':'file', 'name':this.form_name(), 'accept':'image/*'});
			return this.input;
		},
		accepts_focus: false,
		// called by edit dialogue in order to begin the async upload of files
		save: function() {
			if (!this.selected_files) { return; }
			var files = this.selected_files; //this.input[0].files;
			if (files && files.length > 0) {
				this.drop_target.addClass('uploading');
				this.progress_bar().parent().show();
				var file_data = new FormData();
				var file = files[0];
				S.UploadManager.replace(this, file);
			}
			this.selected_files = false;
		},
		is_modified: function() {
			var files = this.selected_files; //this.input[0].files;
			return (files && files.length > 0);
		},
		original_value: function() {
			this.processed_value();
		},
		set_edited_value: function(value) {
			console.log('set_edited_value', value, this.edited_value(), this.original_value())
			if (value === this.edited_value()) {
				// do nothing
			} else {
				this.selected_files = null;
				this.set('value', value);
			}
		}
	});
	return FileField;
})(jQuery, Spontaneous);

