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

console.log('Loading Extensions...')

// Thank you Prototype
function $A(iterable) {
  if (!iterable) return [];
  if (iterable.toArray) return iterable.toArray();
  var length = iterable.length || 0, results = new Array(length);
  while (length--) results[length] = iterable[length];
  return results;
};

jQuery.extend(Function.prototype, {
	bind: function() {
		var __method = this, args = $A(arguments), object = args.shift();
		return function() {
      return __method.apply(object, args.concat($A(arguments)));
    };
	}
});


jQuery.extend(Number.prototype, {
	to_filesize: function() {
		var thou = 1000, units = [" bytes", ' KB', ' MB', ' GB'],
		power = Math.floor(Math.log(this) / Math.log(thou))
		return this / (Math.pow(thou, power)) + units[power]
	}
});
