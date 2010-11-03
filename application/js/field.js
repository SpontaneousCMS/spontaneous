console.log('Loading FieldTypes...')

Spontaneous.FieldTypes = {};
Spontaneous.FieldTypes.StringField = (function($, S) {
	var dom = S.Dom;
	var StringField = function(owner, data) {
		this.name = data.name;
		var content_type = owner.type();
		this.type = content_type.field_prototypes[this.name];
		this.title = this.type.title;
		this.update(data);
	};
	StringField.prototype = $.extend({}, Spontaneous.Properties(), {
		set_value: function(new_value) {
		},
		preview: function() {
			var wrap = $(dom.table, {'class': 'field preview'});
			var row = $(dom.tr);
			row.append($(dom.td, {'class': 'name'}).text(this.title));
			var value = $(dom.td, {'class': 'value'}).text(this.get('value'));
			value.bind('updated', function(event, v) {
				$(this).html(v)
			});

			this.add_listener('value', function(new_value) {
				value.trigger('updated', [new_value])
			});
			row.append(value);
			wrap.append(row);
			return wrap;
		},
		edit: function() {
			var wrap = $(dom.table, {'class': 'field edit'});
			var row = $(dom.tr);
			var label = $(dom.td, {'class': 'name'}).text(this.title);
			row.append(label);
			this.input = $(dom.input, {'class': 'input', 'name':'field['+this.name+'][unprocessed_value]', 'value': this.get('value')})
			var hi = (function(field, label) {
				return function() {
					label.addClass('active');
				};
			})(this, label);
			var low = (function(field, label) {
				return function() {
					label.removeClass('active');
				};
			})(this, label);
			this.input.focus(hi).blur(low);
			row.append($(dom.td, {'class': 'value'}).append(this.input));
			wrap.append(row);
			return wrap;
		},
		focus: function() {
			this.input.focus();
			this.input.select();
		},
		update: function(values) {
			this.data = values;
			this.set('value', values.processed_value);
			this.set('unprocessed_value', values.unprocessed_value);
		},
		value: function() {
			return this.get('value');
		}
	});

	return StringField;
})(jQuery, Spontaneous);

