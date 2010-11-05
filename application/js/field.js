console.log('Loading FieldTypes...')

Spontaneous.FieldTypes = {};

Spontaneous.FieldTypes.StringField = (function($, S) {
	var dom = S.Dom;
	var StringField = function(owner, data) {
		this.name = data.name;
		var content_type = owner.type();
		this.type = content_type.field_prototypes[this.name];
		console.log("StringField#new", this.type);
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
		this.name = data.name;
		var content_type = owner.type();
		this.type = content_type.field_prototypes[this.name];
		this.title = this.type.title;
		this.update(data);
		console.log("ImageField#new", this.name, this.get('value'));
	};
	ImageField.prototype = $.extend({}, Spontaneous.FieldTypes.StringField.prototype, {
		value: function() {
			var value = this.get('value'), el;
			if (value === "") {
				el = $(dom.img, {'src':'/@spontaneous/static/px.gif','class':'missing-image'});
			} else {
				el = $(dom.img, {'src':value});
			}
			var drop = function(event) {
				console.log('drop', event, event.dataTransfer.files)
				event.stopPropagation();
				event.preventDefault();
				var files = event.dataTransfer.files;
				if (files.length > 0) {
					var file = files[0];
					var xhr = new XMLHttpRequest();
					var upload = xhr.upload;
					xhr.open("PUT", "/@spontaneous/upload/1", true);
					xhr.setRequestHeader('X-Filename', file.fileName);
					xhr.send(file);
				}
				return false;
			}.bind(this);

			var drag_enter = function(event) {
				console.log('drag_enter', event, event.dataTransfer)
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(this);
			var drag_over = function(event) {
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(this);
			var drag_leave = function(event) {
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(this);

			el.get(0).addEventListener('drop', drop, true);
			el.bind('dragenter', drag_enter).bind('dragover', drag_over).bind('dragleave', drag_leave);
			return el;
		},
		is_image: function() {
			return true;
		}
	});

	return ImageField;
})(jQuery, Spontaneous);
