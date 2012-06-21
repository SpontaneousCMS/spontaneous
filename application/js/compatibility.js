
// Parts copyright Modernizr:
// * @author        Faruk Ates
// * @author        Paul Irish
// * @copyright     (c) 2009-2011 Faruk Ates.
// * @contributor   Ben Alman

// many thanks to modernizer for working a lot of this out
// should probably just use it instead...
// this does two things:
// 1. Check that the current browser supports the core HTML5 feature set,
// 2. Regularise access to the various APIs, removing vendor prefixes and providing the spec defined methods
// 3. Add some useful CSS-visible attributes to the HTML element
(function() {
	var _window = window, _document = document;
	var testFlexBoxCompatibility = false;
	var prefixes = ' -webkit- -moz- -o- -ms- -khtml- '.split(' ');
	try {

		///////////////////////////// Flexible Box model
		function set_prefixed_property_css(element, property, value, extra) {
			element.style.cssText = prefixes.join(property + ':' + value + ';') + (extra || '');
		}

		function set_prefixed_value_css(element, property, value, extra) {
			property += ':';
			element.style.cssText = (property + prefixes.join(value + ';' + property)).slice(0, -property.length) + (extra || '');
		}


		if (testFlexBoxCompatibility) {
			var docElement = _document.documentElement,
			c = _document.createElement('div'),
			elem = _document.createElement('div'),
			w;

			set_prefixed_value_css(c, 'display', 'box', 'width:42px;padding:0;');
			set_prefixed_property_css(elem, 'box-flex', '1', 'width:10px;');

			c.appendChild(elem);
			docElement.appendChild(c);
			w = elem.offsetWidth
			c.removeChild(elem);
			docElement.removeChild(c);

			if (w !== 42) {
				// console.error(w)
				throw (w) + " Flexible Box Model not supported"
			}
		}

		///////////////////////////// XHR Uploads
		var xhr = new XMLHttpRequest();
		if (!xhr.upload) {
			throw "XMLHttpRequestUpload not supported";
		}

		///////////////////////////// FormData
		try {
			var f = new FormData();
		} catch (e) {
			throw "FormData not supported";
		}

		///////////////////////////// File API / File objects
		if (!_window.File) {
			throw "File API not supported";
		}

		///////////////////////////// File API / objectURLs
		// provide consistent API for creating blob/object URLs
		var createObjectURL = 'createObjectURL', revokeObjectURL = 'revokeObjectURL';
		if (!_window.URL) {
			if (_window.webkitURL) {
				_window.URL = _window.webkitURL;
			} else {
				_window.URL = {};
				if (_window.createBlobURL) {
					_window.URL[createObjectURL] = function(file) {
						return _window.createBlobURL(file);
					};
				} else if (_window[createObjectURL]) {
					_window.URL[createObjectURL] = function(file) {
						return _window[createObjectURL](file);
					};
				} else {
					//// Dont fail this because it's not absolutely essential
					//// & fails iOS devices (though that might be a good thing in some ways, it
					//// would seriously limit users ability to make quick changes on the go, for instance)
					_window.URL[createObjectURL] = function(file) {
						return '';
					}
					// throw "File API not supported";
				}
				if (_window.revokeBlobURL) {
					_window.URL[revokeObjectURL] = function(file) {
						return _window.revokeBlobURL(file);
					};
				} else if (_window[revokeObjectURL]) {
					_window.URL[revokeObjectURL] = function(file) {
						return _window[revokeObjectURL](file);
					};
				} else {
					//// Dont fail this because it's not absolutely essential
					//// & fails iOS devices (though that might be a good thing in some ways, it
					//// would seriously limit users ability to make quick changes on the go, for instance)
					_window.URL[revokeObjectURL] = function(file) {
						return '';
					}
					// throw "File API not supported";
				}
			}
		}
		///////////////////////////// File API / slices
		// normalise access to the File#slice method
		var proto = _window.File.prototype;
		if (!proto.slice) {
			var methods = ['webkitSlice', 'mozSlice'];
			for (var i = 0, ii = methods.length; i < ii; i++) {
				var method = methods[i];
				if (proto[method]) { proto.slice = proto[method]; }
			}
			if (!proto.slice) {
				// not supporting slice just means we can't use the sharded uploader
			}
		}



		///////////////////////////// localStorage
		try {
			var i = localStorage.getItem;
		} catch(e) {
			throw "Local Storage not supported"
		}

		var b = _document.documentElement;
		b.setAttribute('data-useragent',  navigator.userAgent);
		b.setAttribute('data-platform', navigator.platform );
	} catch (e) {
		_window.location.href = "/@spontaneous/unsupported?msg=" + _window.encodeURI(e);
	}
}());
