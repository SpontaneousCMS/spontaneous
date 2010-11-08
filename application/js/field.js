console.log('Loading FieldTypes...')

Spontaneous.FieldTypes = {};

Spontaneous.FieldTypes.StringField = (function($, S) {
	var dom = S.Dom;
	var StringField = function(owner, data) {
		this.content = owner;
		this.name = data.name;
		var content_type = owner.type();
		this.type = content_type.field_prototypes[this.name];
		// console.log("StringField#new", this.type);
		this.title = this.type.title;
		this.update(data);
	};
	StringField.prototype = $.extend({}, Spontaneous.Properties(), {
		set_value: function(new_value) {
		},
		// value: function() {
		// 	return this.get('value');
		// },
		// edit: function() {
		// 	var wrap = $(dom.table, {'class': 'field edit'});
		// 	var row = $(dom.tr);
		// 	var label = $(dom.td, {'class': 'name'}).text(this.title);
		// 	row.append(label);
		// 	this.input = $(dom.input, {'class': 'input', 'name':'field['+this.name+'][unprocessed_value]', 'value': this.get('value')})
		// 	var hi = (function(field, label) {
		// 		return function() {
		// 			label.addClass('active');
		// 		};
		// 	})(this, label);
		// 	var low = (function(field, label) {
		// 		return function() {
		// 			label.removeClass('active');
		// 		};
		// 	})(this, label);
		// 	this.input.focus(hi).blur(low);
		// 	row.append($(dom.td, {'class': 'value'}).append(this.input));
		// 	wrap.append(row);
		// 	return wrap;
		// },
		// focus: function() {
		// 	this.input.focus();
		// 	this.input.select();
		// },
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

		is_image: function() {
			return false;
		}
	});

	return StringField;
})(jQuery, Spontaneous);


Spontaneous.FieldTypes.ImageField = (function($, S) {
	var dom = S.Dom;
	var ImageField = function(owner, data) {
		this.content = owner;
		this.name = data.name;
		var content_type = owner.type();
		this.type = content_type.field_prototypes[this.name];
		this.title = this.type.title;
		this.update(data);
		// console.log("ImageField#new", this.name, this.get('value'));
	};
	ImageField.prototype = $.extend({}, Spontaneous.FieldTypes.StringField.prototype, {
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
					S.UploadManager.add(this, file);
				}
				return false;
			}.bind(this);

			var drag_enter = function(event) {
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
		set_value: function(values) {
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
		}
	});

	return ImageField;
})(jQuery, Spontaneous);
