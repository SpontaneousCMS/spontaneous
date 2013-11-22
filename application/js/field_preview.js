// console.log('Loading FieldPreview...')

Spontaneous.FieldPreview = (function($, S) {
	var dom = S.Dom;

	var FieldPreview = new JS.Class({
		initialize: function(view, wrap_id) {
			this.view = view;
			this.wrap_id = wrap_id;
		},

		depth_class: function() {
			return 'depth-'+this.view.depth();
		},
		has_fields: function() {
			return this.view.has_fields();
		},
		panel: function() {
			var wrapper = dom.div([dom.id(this.wrap_id), 'fields-preview', this.depth_class()])
			// $(dom.div, {'id':this.wrap_id, 'class':'fields-preview ' + this.depth_class()});
			wrapper.append(this.fields_panel(this.view.text_fields(), 'text'));
			wrapper.append(this.fields_panel(this.view.image_fields(), 'image', true));
			if (this.view.mouseover) {
				wrapper.mouseover(this.view.mouseover.bind(this.view))
			}
			if (this.view.mouseout) {
				wrapper.mouseout(this.view.mouseout.bind(this.view))
			}
			wrapper.click(function() {
				this.view.edit(this.field_to_edit);
			}.bind(this))
			return wrapper;
		},
		fields_panel: function(fields, type, ignore_changes) {
			var wrapper = dom.ul('.fields-preview-'+type), __this = this;
			if (fields.length === 0) { wrapper.addClass('empty'); }
			$.each(fields, function(i, field) {
				var li = dom.li();
				var name = dom.div('.name').text(field.title);
				var value = dom.div('.value');
				li.click(function() {
					__this.field_to_edit = field;
				});
				field.activate(value);
				// if (!ignore_changes) {
					field.watch('value', function(field, v) {
						$(this).html(field.preview());
					}.bind(value, field));
				// }
				li.append(name).append(value);
				wrapper.append(li);
				value.html(field.preview(value));
			});
			return wrapper;
		}
	});
	return FieldPreview;
})(jQuery, Spontaneous);
