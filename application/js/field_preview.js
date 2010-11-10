console.log('Loading FieldPreview...')

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
		panel: function() {
			var wrapper = $(dom.div, {'id':this.wrap_id, 'class':'fields-preview ' + this.depth_class()});
			wrapper.append(this.fields_panel(this.content.text_fields(), 'text'));
			wrapper.append(this.fields_panel(this.content.image_fields(), 'image'));
			wrapper.click(function() {
				this.content.edit();
			}.bind(this))
			return wrapper;
		},
		fields_panel: function(fields, type) {
			var wrapper = $(dom.ul, {'class':'fields-preview-'+type});
			$.each(fields, function(i, field) {
				var li = $(dom.li);
				var name = $(dom.div, {'class':'name'}).text(field.title);
				var value = $(dom.div, {'class':'value'}).html(field.preview());
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
