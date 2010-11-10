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
		edit: function() {
			return $(dom.input, {'type':'text', 'id':this.css_id(), 'name':this.form_name(), 'value':this.unprocessed_value()})
		}
	});

	return StringField;
})(jQuery, Spontaneous);


Spontaneous.FieldTypes.ImageField = (function($, S) {
	var dom = S.Dom;
	var ImageField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		preview: function() {
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

			var drop = function(event) {
				dropper.removeClass('drop-active').addClass('uploading');
				var progress_outer = $(dom.div, {'class':'drop-upload-outer'});
				var progress_inner = $(dom.div, {'class':'drop-upload-inner'}).css('width', 0);
				progress_outer.append(progress_inner);
				dropper.append(progress_outer);
				this.progress_bar = progress_inner;
				event.stopPropagation();
				event.preventDefault();
				var files = event.dataTransfer.files;
				if (files.length > 0) {
					var file = files[0];
					S.UploadManager.replace(this, file);
				}
				return false;
			}.bind(this);

			var drag_enter = function(event) {
				// var files = event.originalEvent.dataTransfer.files;
				// console.log(event.originalEvent.dataTransfer, files)
				$(this).addClass('drop-active');
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(dropper);

			var drag_over = function(event) {
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(dropper);

			var drag_leave = function(event) {
				$(this).removeClass('drop-active');
				event.stopPropagation();
				event.preventDefault();
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
			this.set('value', values.src);
			if (this.image) {
				this.image.attr('src', values.src);
			}
		},
		upload_progress: function(position, total) {
			this.progress_bar.css('width', ((position/total)*100) + '%');
			if (position === total) {
				this.drop_target.removeClass('uploading')
				this.progress_bar.parent().remove();
			}
		},
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
			if (this.width() > this.height()) {
				wrap.addClass('landscape');
			}
			var img = $(dom.img, {'src':this.value()})
			var actions = $(dom.div, {'class':'actions'});
			var change = $(dom.a, {'class':'button change'}).text('Change');
			var clear = $(dom.a, {'class':'button clear'}).text('Clear');
			actions.append(change).append(clear);
			wrap.append(img).append(actions);
			return wrap;
		}
	});

	return ImageField;
})(jQuery, Spontaneous);


Spontaneous.FieldTypes.DiscountField = (function($, S) {
	var dom = S.Dom;
	var DiscountField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		edit: function() {
			return $(dom.textarea, {'id':this.css_id(), 'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
		}
	});

	return DiscountField;
})(jQuery, Spontaneous);
