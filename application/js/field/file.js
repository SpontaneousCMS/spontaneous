// console.log('Loading FileField...')
Spontaneous.Field.File = (function($, S) {
	var dom = S.Dom;
	var FileField = new JS.Class(Spontaneous.Field.String, {
		selected_files: false,

		currentValue: function() {
			var pending, v = this.get('value');
			if ((pending = v['__pending__'])) {
				return pending['value'];
			}
			return v;
		},

		currentFilename: function() {
			return this.currentValue()['filename'];
		},

		currentFilesize: function() {
			return this.currentValue()['filesize'];
		},

		currentEditValue: function() {
			var value, pending, ui, v = this.get('value');
			if ((pending = v['__pending__'])) {
				return pending['value'];
			}
			value = v['original'];
			if ((ui = v['__ui__'])) {
				value['path'] = value['src'];
				value['src'] = ui['src'];
			}
			return value;
		},

		preview: function() {
			Spontaneous.UploadManager.register(this);
			var self = this
			, value = this.currentValue()
			, filename = this.currentFilename();
			var wrap = dom.div('.file-field');
			var dropper = dom.div('.file-drop');

			var stopEvent = function(event) {
				event.stopPropagation();
				event.preventDefault();
			};

			var drop = function(event) {
				stopEvent(event);
				dropper.removeClass('drop-active');
				var files = event.dataTransfer.files;

				if (files && files.length > 0) {
					this.selected_files = files;
					S.Ajax.test_field_versions(this.content, [this], this.upload_values.bind(this), this.upload_conflict.bind(this));
				}

				return false;
			}.bind(this);

			var drag_enter = function(event) {
				stopEvent(event);
				$(this).addClass('drop-active');
				return false;
			}.bind(dropper);

			var drag_over = function(event) {
				stopEvent(event);
				return false;
			}.bind(dropper);

			var drag_leave = function(event) {
				stopEvent(event);
				$(this).removeClass('drop-active');
				return false;
			}.bind(dropper);

			dropper.get(0).addEventListener('drop', drop, true);
			dropper.bind('dragenter', drag_enter).bind('dragover', drag_over).bind('dragleave', drag_leave);


			var filename_info = dom.div('.filename');
			var filesize_info = dom.div('.filesize');

			var set_info = function(href, filename, filesize) {
				filename_info.text(filename);
				if (filesize) {
					filesize_info.text(parseFloat(filesize, 10).to_filesize());
				}
			};
			if (value) {
				set_info(value.html, this.currentFilename(), this.currentFilesize());
			}

			dropper.append(this.progress_bar().parent());

			wrap.append(dropper, filename_info, filesize_info);

			this.drop_target = dropper;
			this.value_wrap =  wrap;

			return wrap;
		},
		upload_values: function() {
			var file = this.selected_files[0];
			S.UploadManager.replace(this, file);
		},
		upload_conflict: function(conflict_data) {
			var dialogue = new S.ConflictedFieldDialogue(this, conflict_data);
			dialogue.open();
		},
		unload: function() {
			this.callSuper();
			this.input = null;
			this._progress_bar = null;
			Spontaneous.UploadManager.unregister(this);
		},
		upload_complete: function(values) {
			this.set('value', values.processed_value);
			this.set_version(values.version);
			this.selected_files = null;
			this.disable_progress();
		},
		progress_bar: function() {
			if (!this._progress_bar) {
				var progress_outer = dom.div('.drop-upload-outer').hide();
				var progress_inner = dom.div('.drop-upload-inner').css('width', 0);
				progress_outer.append(progress_inner);
				this._progress_bar = progress_inner;
			}
			return this._progress_bar;
		},
		disable_progress: function() {
			this.progress_bar().parent().hide();
			this.drop_target.add(this.value_wrap).removeClass('uploading')
		},
		upload_progress: function(position, total) {
			if (!this.drop_target.hasClass('uploading')) {
				this.drop_target.add(this.value_wrap).addClass('uploading');
			}
			this.progress_bar().parent().show();
			this.progress_bar().css('width', ((position/total)*100) + '%');
		},
		is_file: function() {
			return true;
		},

		edit: function() {
			var self = this;
			var wrap = dom.div(".file-field", {'style':'position:relative;'});
			var value = this.value();
			var input = this.input();
			var filename_info = dom.div('.filename');
			var filesize_info = dom.div('.filesize');
			var choose_files  = dom.a('.choose').text("Choose file...");

			var set_info = function(filename, filesize) {
				filename_info.text(filename);
				if (filesize) {
					filesize_info.text(parseFloat(filesize, 10).to_filesize());
				}
			};

			var files_selected = function(files) {
				if (files.length > 0) {
					var file = files[0], url = window.URL.createObjectURL(file);
					this.selected_files = files;
					this._edited_value = url;
					window.URL.revokeObjectURL(url);
					set_info(File.filename(file), file.fileSize)
				}
			}.bind(this);

			var onchange = function() {
				var files = input[0].files;
				files_selected(files);
			}.bind(this);

			var onclick = function() {
				self.focus();
				input.trigger('click');
				return false;
			};

			input.change(onchange);

			var dropper = dom.div('.file-drop');

			dropper.add(choose_files).click(onclick);

			// dropper.append(filename_info, filesize_info)
			wrap.append(dropper);

			var stopEvent = function(event) {
				event.stopPropagation();
				event.preventDefault();
			};

			var drop = function(event) {
				stopEvent(event);
				dropper.removeClass('drop-active');
				var files = event.dataTransfer.files;
				files_selected(files);
				return false;
			}.bind(this);

			var drag_enter = function(event) {
				stopEvent(event);
				$(this).addClass('drop-active');
				return false;
			}.bind(dropper);

			var drag_over = function(event) {
				stopEvent(event);
				return false;
			}.bind(dropper);

			var drag_leave = function(event) {
				stopEvent(event);
				$(this).removeClass('drop-active');
				return false;
			}.bind(dropper);

			dropper.get(0).addEventListener('drop', drop, true);
			dropper.bind('dragenter', drag_enter).bind('dragover', drag_over).bind('dragleave', drag_leave);

			if (value) {
				var s = value.html.split('/'), filename = s[s.length - 1];
				set_info(filename, value.filesize);
			}
			wrap.append(input, choose_files, filename_info, filesize_info);


			return wrap;
		},

		filename: function(value) {
			var s = value.html.split('/'), filename = s[s.length - 1];
			return filename;
		},

		accept_mimetype: "*/*",
		generate_input: function() {
			return dom.input({'type':'file', 'name':this.form_name(), 'accept':this.accept_mimetype});
		},
		accepts_focus: false,
		// called by edit dialogue in order to begin the async upload of files
		save: function() {
			if (!this.selected_files) { return; }
			var files = this.selected_files;
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
			var files = this.selected_files;
			return (files && files.length > 0);
		},
		original_value: function() {
			this.processed_value();
		},
		set_edited_value: function(value) {
			if (value === this.edited_value()) {
				// do nothing
			} else {
				this.selected_files = null;
				this.set('value', value);
			}
		},
		stringValue: function() {
			if (this.mark_cleared) {
				this.mark_cleared = false;
				return { name: this.form_name(), value: '' };
			}
			return false; // don't upload this field as text
		},

		mark_cleared: false,

		clear_file: function() {
			// this.set('value', {});
			this.mark_cleared = true;
			this.selected_files = null;
			this.mark_modified();
		}

	});
	return FileField;
})(jQuery, Spontaneous);

