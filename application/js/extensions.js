if (!window.console) {
	window.console = {
		log: function() {},
		warn: function() {},
		error: function() {},
	};
} else {
	// var debug = Spontaneous.debug;
	// window.__console = window.console;
	// window.console = {
	// 	log: function() {
	// 		if (debug) { window.__console.log.apply(window.__console, arguments); }
	// 	},
	// 	warn: function() {
	// 		if (debug) { window.__console.warn.apply(window.__console, arguments); }
	// 	},
	// 	error: function() {
	// 		if (debug) { window.__console.error.apply(window.__console, arguments); }
	// 	}
	// };
}

// console.log('Loading Extensions...')

// Thank you Prototype
function $A(iterable) {
	if (!iterable) return [];
	if (iterable.toArray) return iterable.toArray();
	var length = iterable.length || 0, results = new Array(length);
	while (length--) results[length] = iterable[length];
	return results;
};

(function($) {

	// Cope with changing File API
	File.filename = function(file) {
		return file.fileName || file.name;
	};

	var function_id = 0;

	if (!(typeof Function.prototype.bind === 'function')) {
		Function.prototype.bind = function() {
			var __method = this, args = $A(arguments), object = args.shift();
			return function() {
				return __method.apply(object, args.concat($A(arguments)));
			};
		};
	}
	$.extend(Function.prototype, {
		cache: function(name) {
			var __method = this, id = name || ('__cached__'+(++function_id)), _undefined_;
			return function() {
				if (this[id] === _undefined_) {
					this[id] = __method.apply(this, arguments) || null;
				}
				return this[id];
			};
		}
	});


	$.extend(Number.prototype, {
		to_filesize: function() {
			var thou = 1000, units = [" B", ' kB', ' MB', ' GB'],
			power = Math.floor(Math.log(this) / Math.log(thou))
			return Math.round(this / (Math.pow(thou, power))) + units[power]
		}
	});

	var opacity_change_duration = 200, height_change_duration = 200;

	$.fn.appear = function(callback) {
		var $this = this, siblings = $this.siblings(), fade_in = function() {
			$this.animate({'opacity':1}, {
				duration: opacity_change_duration,
				complete: callback
			});
		};

		if (siblings.length == 0) {
			// skip height animation and just fade the element in
			// otherwise there's this weird gap where nothing seems to be
			// happening. this only happens when the item being 'appeared' is
			// the first in the list
			$this.css({'opacity': 0}).show();
			fade_in();
		} else {
			$this.hide().css({'opacity': 0}).animate({'height':'show'}, {
				duration: height_change_duration,
				complete: fade_in
			});
		}
	};

	$.fn.appear.height_change_duration = height_change_duration;

	$.fn.disappear = function(callback) {
		var $this = this;
		this.animate({'opacity':0}, {
			duration: opacity_change_duration,
			complete: function() {
				$this.animate({'height':'hide'}, {
					duration: height_change_duration,
					complete:callback
				});
			}
		});
	};
}(jQuery));
