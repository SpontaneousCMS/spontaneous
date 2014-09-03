// console.log('Loading ImageField...')
Spontaneous.Field.Image = (function($, S) {
	'use strict';
	var dom = S.Dom;
	var ImageFieldConflictView = new JS.Class(S.Field.String.ConflictView, {

		panel: function() {
			var labels = dom.div('.image-field-conflict.labels.differences'),
				outer = dom.div(),
				image_outer = dom.div('.image-field-conflict.changes.differences'),
				original = dom.div('.original.diff'),
				edited = dom.div('.final.diff');
			var local_label = dom.div('.diff').text('Server version');
			var server_label = dom.div('.diff').text('Your version');
			original.append(dom.img().attr('src', this.values.server_original)).click(function() {
				this.useValue(this.values.server_original);
				edited.add(original).removeClass('selected');
				original.addClass('selected');
			}.bind(this));

			edited.append(dom.img().attr('src', this.values.local_edited)).click(function() {
				this.useValue(this.values.local_edited);
				edited.add(original).removeClass('selected');
				edited.addClass('selected');
			}.bind(this));
			labels.append(local_label, server_label);
			image_outer.append(original, edited);
			outer.append(labels, image_outer);
			return outer;
		}
	});

	var ImageField = new JS.Class(Spontaneous.Field.File, {
		is_image: function() {
			return true;
		},

		unload: function() {
			this.callSuper();
			this.image = null;
			this._progress_bar = null;
		},

		// progress_bar: function() {
		// 	if (!this._progress_bar) {
		// 		var progress_outer = dom.div('.drop-upload-outer').hide();
		// 		var progress_inner = dom.div('.drop-upload-inner').css('width', 0);
		// 		progress_outer.append(progress_inner);
		// 		this._progress_bar = progress_inner;
		// 	}
		// 	return this._progress_bar;
		// },


		upload_progress: function(position, total) {
			this.spinner().stop();
			this.waiting.find(':visible').hide();
			this.callSuper();
		},

		currentValue: function() {
			var pending, v = this.get('value');
			if ((pending = v.__pending__)) {
				pending.path = pending.src;
				return pending.value;
			}
			return v.__ui__ || v.original || {};
		},

		currentEditValue: function() {
			var value, pending, ui, v = this.get('value');
			if ((pending = v.__pending__)) {
				return pending.value;
			}
			value = v.original;
			if ((ui = v.__ui__)) {
				value.path = value.src;
				value.src = ui.src;
			}
			return value;
		},

		currentFilename: function() {
			var v = this.get('value');
			return (v.__pending__ || v.original).filename;
		},
		/*
		* HACK: The async nature of image updates means that the version setting
		* may be out of date not because of the actions of another, but because
		* the field version has been updated in the background.
		* The right way to do this would be to use an event to update the field
		* values at the point where the update is complete, but that's a big change.
		*
		* If I do that then I could use it to update all field values across all sessions
		* and avoid most conflicts by keeping the field values up-to-date automatically
		* but I'm not ready for that just yet...
		*
		* Instead hackily use the pending version and hope it's not going to cause
		* weird problems with simultaneous updates.
		*/
		version: function() {
			var pending, value = this.get('value');
			if ((pending = value.__pending__)) {
				return pending.version;
			}
			return this.data.version;
		},

		preview: function() {
			Spontaneous.UploadManager.register(this);
			var self = this
, value = this.currentValue()
			, src = value.src
, img = null
, dim = 45;
			// , container = container.parent('li');

			if (src === '') {
				img = dom.img('.missing-image', {'src':''});
			} else {
				img = dom.img();
				img.load(function() {
					var r = this.width/this.height, $this = $(this), h = $this.height(), dh = 0;
					if (r >= 1) { // landscape -- fit image vertically
						// tag for extra css styles applicable to landscape images
						// container.addClass('landscape');
						if (h <= dim) {
							dh = (dim - h)/2;
						}
					}
					$this.css('top', dom.px(dh));
				});
				img.attr({'src':src});
			}

			img.error(function() {
				$(this).addClass('missing');
			});

			this.image = img;

			var outer = dom.div('.image-outer');
			var dropper = dom.div('.image-drop');
			var waiting = dom.div('.waiting').hide();
			outer.append(img);
			outer.append(waiting);
			outer.append(dropper);

			dropper.append(this.progress_bar().parent());
			this.waiting = waiting;

			var drop = function(event) {
				event.stopPropagation();
				event.preventDefault();
				dropper.removeClass('drop-active').addClass('uploading');
				var files = event.dataTransfer.files;
				this.waiting.show();
				this.spinner().indeterminate();

				if (files.length > 0) {
					this.select_files(files);
					var file = files[0],
					url = this.createObjectURL(file)
					, image = this.image;
					this._edited_value = url;
					image.__start_upload = true;
					image.bind('load', function() {
						if (this.image.__start_upload) {
							image.__start_upload = false;
							S.Ajax.test_field_versions(this.content, [this], this.upload_values.bind(this), this.upload_conflict.bind(this));
						}
						var img = image[0], w = img.width, h = img.height, r = w/h;
						if (r > 1) {
							// container.addClass('landscape');
						} else {
							// container.removeClass('landscape');
						}
					}.bind(this));
					image.attr('src', url);
				}
				return false;
			}.bind(this);

			var drag_enter = function(event) {
				event.stopPropagation();
				event.preventDefault();
				$(this).addClass('drop-active');
				return false;
			}.bind(dropper);

			var drag_over = function(event) {
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(dropper);

			var drag_leave = function(event) {
				event.stopPropagation();
				event.preventDefault();
				$(this).removeClass('drop-active');
				return false;
			}.bind(dropper);

			dropper.get(0).addEventListener('drop', drop, true);
			dropper.bind('dragenter', drag_enter).bind('dragover', drag_over).bind('dragleave', drag_leave);
			this.value_wrap = outer;
			this.drop_target = dropper;
			this.preview_img = img;
			return outer;
		},
		conflicts_resolved: function(resolution_list) {
			// console.log('conflicts_resolved', resolution_list)
			var resolution = resolution_list[0];
			this.set_edited_value(resolution.value);
			this.set_version(resolution.version);
			if (this.is_modified()) {
				this.upload_values();
			} else {
				this.disable_progress();
			}
		},
		disable_progress: function() {
			this.spinner().stop();
			this.callSuper();
		},
		spinner: function() {
			if (!this._spinner) {
				this._spinner = Spontaneous.Progress(this.waiting[0], 16, {
					spinner_fg_color: '#fff',
					period: 800
				});
				this._spinner.init();
			}
			return this._spinner;
		},
		upload_complete: function(values) {
			this.mark_unmodified();
			this.callSuper(values);
			if (values) {
				var value = this.currentValue();
				if (this.image) {
					var img = new Image();
					img.onload = function() {
						this.image.attr('src', value.src);
					}.bind(this);
					img.src = value.src;
				}
			}
		},

		width: function() {
			if (this.data.values && this.currentValue()) {
				return this.currentValue().width;
			}
			return 0;
		},
		height: function() {
			if (this.data.values && this.currentValue()) {
				return this.currentValue().height;
			}
			return 0;
		},
		edit: function() {
			var wrap = dom.div(),
			drop_wrap = dom.div({'style':'position:relative;'}),
				value = this.currentEditValue(),
				src = value.src,
				img = dom.img({'src':src}),
				info, sizes, filename_info, filesize_info, dimensions_info;

			if (value.width >= value.height) {
				wrap.addClass('landscape');
			} else {
				wrap.removeClass('landscape');
			}

			info = dom.div('.info');
			sizes = dom.div('.sizes');
			filename_info = dom.div('.filename');
			filesize_info = dom.div('.filesize');
			dimensions_info = dom.div('.dimensions');
			sizes.append(filesize_info, dimensions_info);
			info.append(filename_info);
			info.append(sizes);

			var set_dimensions = function(width, height) {
				if (width && height) {
					dimensions_info.text(width + 'x' + height);
				} else {
					dimensions_info.text('');
				}
			};

			var set_info = function(filename, filesize, width, height) {
				filename_info.text(filename);
				if (filesize) {
					filesize_info.text(parseFloat(filesize, 10).to_filesize());
				} else if (filesize === 0 || filesize === '0') {
					filesize_info.text('');
				}

				set_dimensions(width, height);
			};

			var files_selected = function(files) {
				if (files.length > 0) {
					var file = files[0], url = this.createObjectURL(file);
					img.attr('src', url).removeClass('empty');
					this.select_files(files);
					img.attr('src', url);
					this._edited_value = url;
					this.image.attr('src', url);
					set_info(File.filename(file), file.fileSize, null, null);
				}
			}.bind(this);

			var onchange = function() {
				var files = this.input[0].files;
				files_selected(files);
			}.bind(this);
			var input = this.get_input().change(onchange);

			var onclick = function() {
				input.trigger('click');
				return false;
			};

			if (src === '') { img.addClass('empty'); }

			var dropper = dom.div('.image-drop').click(onclick);

			var actions = dom.div('.actions');
			var clear = dom.a('.button.clear').text('Clear').click(function() {
				img.css({width: dom.px(img.width()), height: dom.px(img.height())}).attr('src', '/@spontaneous/static/px.gif');
				set_info('', 0, null, null);
				this.clear_file();
			}.bind(this));
			actions.append(input, clear);
			drop_wrap.append(dropper);


			var drop = function(event) {
				event.stopPropagation();
				event.preventDefault();
				dropper.removeClass('drop-active');
				var files = event.dataTransfer.files;
				files_selected(files);
				return false;
			}.bind(this);

			var drag_enter = function(event) {
				event.stopPropagation();
				event.preventDefault();
				$(this).addClass('drop-active');
				return false;
			}.bind(dropper);

			var drag_over = function(event) {
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(dropper);

			var drag_leave = function(event) {
				event.stopPropagation();
				event.preventDefault();
				$(this).removeClass('drop-active');
				return false;
			}.bind(dropper);

			dropper.get(0).addEventListener('drop', drop, true);
			dropper.bind('dragenter', drag_enter).bind('dragover', drag_over).bind('dragleave', drag_leave);

			drop_wrap.append(img, info);
			wrap.append(drop_wrap, actions);

			if (value) {
				// var s = value.path.split('/'), filename = s[s.length - 1];
				set_info(this.currentFilename(), value.filesize, value.width, value.height);
			}
			this.preview_img = img;
			return wrap;
		},

		select_files: function(files) {
			this.selected_files = files;
			this.mark_modified();
		},

		is_modified: function() {
			return this.get_modified_state();
		},

		get_input: function() {
			this.input = this.generate_input();
			return this.input;
		},
		cancel_edit: function() {
			this.image.attr('src', this.currentValue().src);
		},
		conflict_view: function(dialogue, conflict) {
			return new ImageFieldConflictView(dialogue, conflict);
		},
		edited_value: function() {
			return this._edited_value;
		},
		set_edited_value: function(value) {
			this.preview_img.attr('src', value);
			this.callSuper(value);
		},
		accept_mimetype: 'image/*'
	});

	ImageField.ConflictView = ImageFieldConflictView;

	return ImageField;
})(jQuery, Spontaneous);
