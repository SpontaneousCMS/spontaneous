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
			var value = this.get('value');
			if (value === "") {
				return $(dom.img, {'src':'/@spontaneous/static/px.gif','class':'missing-image'});
			} else {
				return $(dom.img, {'src':value});
			}
		},
		is_image: function() {
			return true;
		}
	});

	return ImageField;
})(jQuery, Spontaneous);
