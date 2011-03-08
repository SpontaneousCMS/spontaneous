// console.log('Loading Progress...');

Spontaneous.Progress = (function($, S) {
	var Progress = function(parent, size, options) {
		var defaults = {
			spinner_fg_color: "#000000", // colour
			spinner_bg_color: null, // null  or false for transparent
			progress_fg_color: "#000000", // colour
			progress_bg_color: false, // null  or false for transparent
			spinner_alpha: 1,
			progress_alpha: 1,
			period: 550, // (ms) time taken for spinner to complete one revolution
			segments: 12,  // number of bars in spinner
			segment_length: 0.47, // length of spinner bar as fraction of total radius
			segment_width: 0.6, // spinner bar thickness. 1 means inner edges form unbroken circle
			trail_length: 1.1, // trail length of 1 means shaded bars go all the way around
			rounded: true,
			shaded: false,
		}
		if (typeof options == 'undefined') options = {};
		var settings = {};
		for (k in defaults) {
			settings[k] = defaults[k];
		}

		for (k in options) {
			settings[k] = options[k];
		}
		return {
			container: parent,
			size: size,
			_canvas: false,
			defaults: defaults,
			options: settings,

			_color: {},

			// forces the addition of the canvas. normally this is lazily added
			// only when the progress indicator is actually used
			init: function() {
				var c = this.canvas();
			},

			context: function() {
				return this.canvas().getContext('2d');
			},

			colour: function(t, l, alpha) {
				var c = t + '_' + l + '_color';
				if (typeof alpha == 'undefined') alpha = this.options[t+'_alpha'];
				if (!this._color[c]) {
					this._color[c] = this._parse_color(this.options[c]);
				}
				return "rgba("+this._color[c][0]+", "+this._color[c][1]+", "+this._color[c][2]+", " +alpha+ ")";
			},

			canvas: function() {
				var c;
				if (this.container && !this._canvas) {

					c = document.createElement('canvas');
					c.width = this.size;
					c.height = this.size;
					// _log(typeof this.container)
					var e = null;
					if (typeof this.container == 'string') {
						this.container = document.getElementById(this.container);
					}
					this.container.appendChild(c);
					this._canvas = c;

				}
				return this._canvas;
			},

			_percent: false,

			// thanks to Stoyan Stefanov
			// for original pie drawing code:
			// http://www.phpied.com/canvas-pie/
			update: function(percent) {
				this._indeterminate = false;

				percent = Math.max(0.1, parseFloat(percent)); // always show something...
				this._percent = percent;
				var ctx = this.context();

				var radius = this.size / 2;
				var center = this.size / 2;
				ctx.clearRect(0,0,this.size,this.size);
				var colour;

				if (this.options.progress_bg_color) {
					colour = this.colour('progress', 'bg');
					ctx.beginPath();
					ctx.moveTo(center, center);
					ctx.arc(  // draw next arc
						center, // x
						center, // y
						radius,    // radius
						Math.PI * -0.5, // -0.5 sets set the start to be top
						Math.PI * 2,
						false // clockwise?
					);
					ctx.closePath();
					ctx.fillStyle = colour;    // color
					ctx.fill();
				}
				colour = this.colour('progress', 'fg');


				var a = (parseFloat(percent)/100.0);
				ctx.beginPath();
				ctx.moveTo(center, center); // center of the pie
				ctx.arc(  // draw next arc
					center, // x
					center, // y
					radius,    // radius
					Math.PI * -0.5, // -0.5 sets set the start to be top
					Math.PI * (- 0.5 + 2 * a),
					false // clockwise?
				);

				ctx.lineTo(center, center); // line back to the center
				ctx.closePath();
				ctx.fillStyle = colour;    // color
				ctx.fill();
			},

			_redraw: function() {
				if (this._percent) this.update(this._percent);
			},

			_indeterminate: false,
			_indeterminate_interval: false,

			indeterminate: function() {
				if (this._indeterminate) return;
				this._indeterminate = true;
				var __spinner = this;
				var __spinning = function() {
					__spinner._update_indeterminate();
				}
				this._draw_indeterminate();

				this._indeterminate_interval = setInterval(__spinning, parseFloat(this.options.period) / this.options.segments);
			},
			spin: function() {this.indeterminate()},
			start: function() {this.indeterminate()},

			_spin_angle: 0,
			_spin_increment: function() { return 2 / this.options.segments },

			_update_indeterminate: function() {
				if (!this._indeterminate) {
					this.pause();
					return;
				}
				this._spin_angle += this._spin_increment();
				this._draw_indeterminate();
			},

			_draw_indeterminate: function() {
				var ctx = this.context();

				var radius = this._radius();
				var center = this._center();
				var inc = this._spin_increment();

				ctx.clearRect(0,0,this.size,this.size);
				var r1 = radius - (radius * this.options.segment_length);

				var p = ((2.0 * Math.PI * r1) / this.options.segments) * this.options.segment_width ;
				var r2 = radius;

				if (this.options.rounded) r2 -= p/2;

				for (var i = 0; i < this.options.segments; i++) {
					var offset = (inc * i);
					var a = Math.PI * (1 -this._spin_angle + offset);

					ctx.beginPath();

					if (this.options.rounded) {
						this._draw_rounded(ctx, center, r1, r2, a, p)
					} else {
						this._draw_square(ctx, center, r1, r2, a, p)
					}
					ctx.closePath();
					ctx.fillStyle = this._fill(ctx, i);
					ctx.fill();
				}
			},

			_draw_rounded: function(ctx, c, r1, r2, a, p) {
				var sin = Math.sin(a);
				var cos = Math.cos(a);
				var a1 = Math.PI - a;
				var a2 = 2 * Math.PI - a;
				ctx.arc(
					c + r1 * sin, // x
					c + r1 * cos, // y
					p/2,// radius
					a1,
					a2,
					false
				);

				ctx.arc(
					c + r2 * sin, // x
					c + r2 * cos, // y
					p/2, // radius
					a2,
					a1,
					false
				);

			},

			_draw_square: function(ctx, c, r1, r2, a, p) {
				var sin = Math.sin(a);
				var cos = Math.cos(a);
				var dx = (p/2.0) * cos;
				var dy = (p/2.0) * sin;

				var x0 = c + r1 * sin;
				var y0 = c + r1 * cos;

				var x1 = c + r1 * sin + dx
				var y1 = c + r1 * cos - dy;

				var x2 = c + r2 * sin + dx
				var y2 = c + r2 * cos - dy;

				var x3 = c + r2 * sin - dx;
				var y3 = c + r2 * cos + dy;

				var x4 = c + r1 * sin - dx;
				var y4 = c + r1 * cos + dy;

				ctx.moveTo(x1, y1);
				ctx.lineTo(x2, y2);
				ctx.lineTo(x3, y3);
				ctx.lineTo(x4, y4);

			},

			_fill: function(ctx, i) {
				if (this.options.shaded) {
					return this._shaded_fill(ctx, i);
				} else {
					return this._solid_fill(ctx, i);
				}
			},

			_solid_fill: function(ctx, i) {
				return this.colour('spinner','fg', this._alpha_for_segment(i));
			},

			_shaded_fill: function(ctx, i) {
				var c = this._center();
				var gradient = ctx.createRadialGradient(c, c, 0, c, c, this._radius());
				gradient.addColorStop(0.3, this.colour('spinner', 'fg', 0));
				gradient.addColorStop(1, this.colour('spinner', 'fg', this._alpha_for_segment(i)));
				return gradient;

			},

			_alpha_for_segment: function(n) {
				var x = (n / this.options.segments);
				// gotta be a smart way to figure out these constants
				var a = Math.max(0, this.options.spinner_alpha * ((1.0 / (5.0 * ((x / this.options.trail_length) + (1.0/5.8)))) - 0.168));
				return a;
			},

			_radius: function() {
				return this.size/2;
			},

			_center: function() {
				return this._radius();
			},

			_parse_color: function(css_colour) {
				if (css_colour.charAt(0) == '#') {
					css_colour = css_colour.substr(1, 6);
				}
				css_colour = css_colour.replace(/ /g,'');
				css_colour = css_colour.toLowerCase();
				var hex = [];
				if (css_colour.length == 3) {
					for (var i = 0; i < 3; i++) {
						hex[hex.length] = css_colour.charAt(i) + css_colour.charAt(i);
					}
				} else {
					for (var i = 0; i < 3; i++) {
						hex[hex.length] = css_colour.substr(i*2, 2);
					}
				}
				var rgb = [];
				for (var i = 0; i < hex.length; i++) {
					rgb[i] = parseInt(hex[i], 16);
				}
				return rgb;
			},

			pause: function() {
				// pauses indeterminate spinner
				this._indeterminate = false;
				// this._spin_angle = 0;
				clearInterval(this._indeterminate_interval);
			},

			stop: function() {
				this.pause();
				this.clear();
			},

			clear: function() {
				this.context().clearRect(0,0,this.size,this.size);
			},

			_disappear_interval: null,

			disappear: function(duration) {
				if (typeof duration === 'undefined') duration = 1000;
				var disappearing = this;
				var orig_alpha = this.options.spinner_alpha;
				var finish_time = (new Date()).valueOf() + duration;
				var disappear = function() {
					if (disappearing.options.spinner_alpha <= 0) {
						clearInterval(disappearing._disappear_interval);
						disappearing.stop();
						disappearing.options.spinner_alpha = orig_alpha;
					} else {
						var now = (new Date()).valueOf(), remaining = (finish_time - now)/duration;
						disappearing.options.spinner_alpha = orig_alpha * remaining;
					}
				}

				this._disappear_interval = setInterval(disappear, 50);
			},

			set_options: function(o) {
				this.options = o;
				this._color = {};
				this._spin_angle = 0;
				if (this._indeterminate) {
					this.stop();
					this.indeterminate();
				} else {
					this._redraw()
				}
			}
		}
	}
	return Progress;
})(jQuery, Spontaneous);
