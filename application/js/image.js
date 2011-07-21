
// Useful wrapper around image fields
Spontaneous.Image = (function($, S) {
	var dom = Spontaneous.Dom;
	var Image = new JS.Class({
		initialize: function(field) {
			this.field = field;
		},
		fit: function(width, height) {
			if (this.is_empty()) {
				return dom.span();
			}
			var dim = this.fit_dimensions(width, height);
			return dom.img({'src':this.src()}).attr('width',dim.width).attr('height',dim.height);
		},
		fit_dimensions: function(width, height) {
			var ratio = 1.0;
			if (this.is_landscape()) {
				if (this.width() > width) {
					ratio = width/this.width();
				}
			} else {
				if (this.height() > height) {
					ratio = height/this.height();
				}
			}
			return {'width':(this.width() * ratio), 'height':(this.height() * ratio)};
		},
		fit_dimensions_inverse: function(width, height) {
			var ratio = 1.0;
			if (this.is_portrait()) {
				if (this.width() > width) {
					ratio = width/this.width();
				}
			} else {
				if (this.height() > height) {
					ratio = height/this.height();
				}
			}
			return {'width':(this.width() * ratio), 'height':(this.height() * ratio)};
		},
		icon: function(width, height) {
			if (this.is_empty()) {
				return dom.span();
			}
			var dim = this.fit_dimensions_inverse(width, height), wrap = dom.div('.icon-wrap', {'width':dom.px(width), 'height':dom.px(height)});
			wrap.append(dom.img({'src':this.src()}).css({'left':dom.px((width - dim.width)/2), 'top':dom.px((height - dim.height)/2)}).attr('width',dim.width).attr('height',dim.height));
			return wrap;
		},
		src: function() {
			return this.field.attributes.original.src;
		},
		width: function() {
			if (this.is_empty()) { return 0; }
			return this.field.attributes.original.width;
		},
		height: function() {
			if (this.is_empty()) { return 0; }
			return this.field.attributes.original.height;
		},
		is_landscape: function() {
			return this.width() >= this.height();
		},
		is_portrait: function() {
			return this.height() > this.width();
		},
		is_empty: function() {
			return !this.field.attributes.original;
		}
	});
	return Image;
}());
