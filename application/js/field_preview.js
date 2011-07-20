// console.log('Loading FieldPreview...')

Spontaneous.FieldPreview = (function($, S) {
	var dom = S.Dom;

	var FieldPreview = new JS.Class({
		initialize: function(content, wrap_id) {
			this.content = content;
			this.wrap_id = wrap_id;
		},

		depth_class: function() {
			return 'depth-'+this.content.depth();
		},
		has_fields: function() {
			return this.content.field_list().length > 0;
		},
		panel: function() {
			var wrapper = dom.div([dom.id(this.wrap_id), 'fields-preview', this.depth_class()])
			// $(dom.div, {'id':this.wrap_id, 'class':'fields-preview ' + this.depth_class()});
			wrapper.append(this.fields_panel(this.content.text_fields(), 'text'));
			wrapper.append(this.fields_panel(this.content.image_fields(), 'image'));
			if (this.content.mouseover) {
				wrapper.mouseover(this.content.mouseover.bind(this.content))
			}
			if (this.content.mouseout) {
				wrapper.mouseout(this.content.mouseout.bind(this.content))
			}
			wrapper.click(function() {
				this.content.edit(this.field_to_edit);
			}.bind(this))
			return wrapper;
		},
		fields_panel: function(fields, type) {
			var wrapper = dom.ul('.fields-preview-'+type), __this = this;
			if (fields.length === 0) { wrapper.addClass('empty'); }
			$.each(fields, function(i, field) {
				var li = dom.li();
				var name = dom.div('.name').text(field.title);
				var value = dom.div('.value').html(field.preview());
				li.click(function() {
					__this.field_to_edit = field;
				})
				field.activate(value);
				field.add_listener('value', function(field, v) { $(this).html(field.preview()) }.bind(value, field));
				li.append(name).append(value);
				wrapper.append(li);
			});
			return wrapper;
		}
	});
	return FieldPreview;
})(jQuery, Spontaneous);
