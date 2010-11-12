console.log('Loading FieldTypes...')

Spontaneous.FieldTypes = {};

Spontaneous.FieldTypes.StringField = (function($, S) {
	var dom = S.Dom;
	var StringField = new JS.Class({
		include: Spontaneous.Properties,

		initialize: function(owner, data) {
			this.content = owner;
			this.name = data.name;
			var content_type = owner.type();
			this.type = content_type.field_prototypes[this.name];
			this.title = this.type.title;
			this.update(data);
		},
		uid: function() {
			return this.content.uid() + '['+this.name+']';
		},
		set_value: function(new_value) {
		},

		update: function(values) {
			this.data = values;
			this.set('value', values.processed_value);
			this.set('unprocessed_value', values.unprocessed_value);
		},
		preview: function() {
			return this.get('value')
		},
		activate: function(el) {
			el.find('a[href^="/"]').click(function() { 
				S.Location.load_path($(this).attr('href'));
				return false;
			});
		},
		value: function() {
			return this.get('value');
		},
		unprocessed_value: function() {
			return this.data.unprocessed_value;
		},
		is_image: function() {
			return false;
		},
		is_file: function() {
			return false;
		},

		id: function() {
			return this.content.id();
		},
		css_id: function() {
			return 'field-'+this.name+'-'+this.id();
		},
		form_name: function() {
			return 'field['+this.name+'][unprocessed_value]';
		},
		label: function() {
			return this.title;
		},
		get_input: function() {
			this.input = $(dom.input, {'type':'text', 'id':this.css_id(), 'name':this.form_name(), 'value':this.unprocessed_value()})
			return this.input;
		},
		edit: function() {
			return this.get_input();
		}
	});

	return StringField;
})(jQuery, Spontaneous);


Spontaneous.FieldTypes.FileField = (function($, S) {
	var dom = S.Dom;
	var FileField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		preview: function() {
			Spontaneous.UploadManager.register(this);
			return this.callSuper();
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
Spontaneous.FieldTypes.ImageField = (function($, S) {
	var dom = S.Dom;
	var ImageField = new JS.Class(Spontaneous.FieldTypes.FileField, {
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


Spontaneous.FieldTypes.DiscountField = (function($, S) {
	var dom = S.Dom;
	var DiscountField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		get_input: function() {
			this.input = $(dom.textarea, {'id':this.css_id(), 'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
			return this.input;
		},
		edit: function() {
			return this.get_input();
		}
	});

	return DiscountField;
})(jQuery, Spontaneous);
