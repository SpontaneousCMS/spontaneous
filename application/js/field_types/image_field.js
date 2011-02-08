console.log('Loading ImageField...')
Spontaneous.FieldTypes.ImageField = (function($, S) {
	var dom = S.Dom;
	var ImageField = new JS.Class(Spontaneous.FieldTypes.FileField, {
		unload: function() {
			this.callSuper();
			this.image = null;
			this._progress_bar = null;
		},
		progress_bar: function() {
			if (!this._progress_bar) {
				var progress_outer = $(dom.div, {'class':'drop-upload-outer'}).hide();
				var progress_inner = $(dom.div, {'class':'drop-upload-inner'}).css('width', 0);
				progress_outer.append(progress_inner);
				this._progress_bar = progress_inner;
			}
			return this._progress_bar;
		},
		preview: function() {
			Spontaneous.UploadManager.register(this);
			var value = this.get('value'), img = null, dim = 45;
			if (value === "") {
				img = $(dom.img, {'src':'/@spontaneous/static/px.gif','class':'missing-image'});
			} else {
				img = $(dom.img, {'src':value});
			}
			img.error(function() {
				console.log("***** MISSING IMAGE", value);
				$(this).addClass('missing');
			});
			img.load(function() {
				var r = this.width/this.height, $this = $(this), h = $this.height(), dh = 0;
				if (r >= 1 && h < dim) { // landscape -- fit image vertically
					var dh = (dim - h)/2;
				}
				$this.css('top', (dh) + 'px');
			});
			this.image = img;

			var outer = $(dom.div);
			var dropper = $(dom.div, {'class':'image-drop'});
			outer.append(img);
			outer.append(dropper);
			dropper.append(this.progress_bar().parent());

			var drop = function(event) {
				event.stopPropagation();
				event.preventDefault();
				dropper.removeClass('drop-active').addClass('uploading');
				var files = event.dataTransfer.files;
				if (files.length > 0) {
					var file = files[0], url = window.createBlobURL(file);
					this.image.attr('src', url)
					S.UploadManager.replace(this, file);
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
			this.drop_target = dropper;
			return outer;
		},
		is_image: function() {
			return true;
		},
		upload_complete: function(values) {
			this.callSuper(values)
			this.set('value', values.src);
			if (this.image) {
				this.image.attr('src', values.src);
			}
		},
		// upload_progress: function(position, total) {
		// 	this.progress_bar.css('width', ((position/total)*100) + '%');
		// 	if (position === total) {
		// 		this.drop_target.removeClass('uploading')
		// 		this.progress_bar.parent().remove();
		// 	}
		// },
		width: function() {
			if (this.data.attributes && this.data.attributes.original) {
				return this.data.attributes.original.width;
			}
			return 0;
		},
		height: function() {
			if (this.data.attributes && this.data.attributes.original) {
				return this.data.attributes.original.height;
			}
			return 0;
		},
		edit: function() {
			var wrap = $(dom.div);
			var onclick = function() {
				input.trigger('click');
				return false;
			};
			var src = this.value();
			var img = $(dom.img, {'src':src}).click(onclick).load(function() {
				if (this.width > this.height) {
					wrap.addClass('landscape');
				} else {
					wrap.removeClass('landscape');
				}
			});
			if (src == '') { img.addClass('empty'); }
			var onchange = function() {
				var files = this.input[0].files;
				if (files.length > 0) {
					var file = files[0], url = window.createBlobURL(file);
					img.attr('src', url).removeClass('empty');
					this.image.attr('src', url)
				}
			}.bind(this);
			var input = this.get_input().change(onchange);
			var actions = $(dom.div, {'class':'actions'});
			var change = $(dom.a, {'class':'button change'}).text('Change').click(onclick);
			var clear = $(dom.a, {'class':'button clear'}).text('Clear');
			actions.append(input).append(change).append(clear);
			wrap.append(img).append(actions);
			return wrap;
		}
	});

	return ImageField;
})(jQuery, Spontaneous);

