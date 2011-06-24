
// Useful wrapper around image fields
Spontaneous.Image = (function($, S) {
	var dom = Spontaneous.Dom;
	var Image = new JS.Class({
		initialize: function(field) {
			this.field = field;
		},
		fit: function(width, height) {
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
			return dom.img({'src':this.src()}).attr('width',(this.width() * ratio)).attr('height',this.height() * ratio)
		},
		src: function() {
			return this.field.attributes.original.src;
		},
		width: function() {
			return this.field.attributes.original.width;
		},
		height: function() {
			return this.field.attributes.original.height;
		},
		is_landscape: function() {
			return this.width() >= this.height();
		},
		is_portrait: function() {
			return this.height() > this.width();
		}
	});
	return Image;
}());
