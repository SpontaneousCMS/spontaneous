console.log('Loading FileField...')
Spontaneous.FieldTypes.FileField = (function($, S) {
	var dom = S.Dom;
	var FileField = new JS.Class(Spontaneous.FieldTypes.StringField, {
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
			this.input = $(dom.input, {'type':'file', 'name':this.form_name(), 'accept':'image/*'});
			return this.input;
		},
		// called by edit dialogue in order to begin the async upload of files
		save: function() {
			if (!this.input) { return; }
			var files = this.input[0].files;
			if (files.length > 0) {
				this.drop_target.addClass('uploading');
				this.progress_bar().parent().show();
				var file_data = new FormData();
				var file = files[0];
				S.UploadManager.replace(this, file);
			}
		}
	});
	return FileField;
})(jQuery, Spontaneous);

