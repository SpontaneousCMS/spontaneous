console.log('Loading FieldPreview...')

Spontaneous.FieldPreview = (function($, S) {
	var dom = S.Dom;

	var FieldPreview = function(content, wrap_id) {
		this.content = content;
		this.wrap_id = wrap_id;
		console.log('FieldPreview#new', content)
	};

	FieldPreview.prototype = {
		depth_class: function() {
			return 'depth-'+this.content.depth();
		},
		panel: function() {
			var wrapper = $(dom.div, {'id':this.wrap_id, 'class':'fields-preview ' + this.depth_class()});
			console.log('FieldPreview#panel', this.text_fields(), this.image_fields());
			wrapper.append(this.fields_panel(this.text_fields(), 'text'));
			wrapper.append(this.fields_panel(this.image_fields(), 'image'));
			return wrapper;
		},
		fields_panel: function(fields, type) {
			var wrapper = $(dom.ul, {'class':'fields-preview-'+type});
			$.each(fields, function(i, field) {
				var li = $(dom.li);
				var name = $(dom.div, {'class':'name'}).text(field.title);
				var value = $(dom.div, {'class':'value'}).html(field.preview());
				li.append(name).append(value);
				wrapper.append(li);
			});
			return wrapper;
		},
		text_fields: function() {
			var tf = [], ff = this.fields();
			$.each(ff, function(i, f) {
				console.log("FieldPreview#text_fields", f, f.is_image)
				if (!f.is_image()) {
					tf.push(f);
				}
			});
			return tf;
		},
		image_fields: function() {
			var imf = [], ff = this.fields();
			$.each(ff, function(i, f) {
				if (f.is_image()) {
					imf.push(f);
				}
			});
			return imf;
		},
		fields: function() {
			return this.content.fields();
		}
	};
	return FieldPreview;
})(jQuery, Spontaneous);
