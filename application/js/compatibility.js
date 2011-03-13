
// Parts copyright Modernizr:
// * @author        Faruk Ates
// * @author        Paul Irish
// * @copyright     (c) 2009-2011 Faruk Ates.
// * @contributor   Ben Alman

// many thanks to modernizer for working a lot of this out
// should probably just use it instead...
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

	var docElement = document.documentElement,
		c = document.createElement('div'),
		elem = document.createElement('div'),
		w;

	set_prefixed_value_css(c, 'display', 'box', 'width:42px;padding:0;');
	set_prefixed_property_css(elem, 'box-flex', '1', 'width:10px;');

	c.appendChild(elem);
	docElement.appendChild(c);
	w = elem.offsetWidth
	c.removeChild(elem);
	docElement.removeChild(c);

	if (w !== 42) {
		throw "Flexible Box Model not supported"
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

	///////////////////////////// File API / objectURLs
	// provide consistent API for creating blob/object URLs
	if (!window.URL) {
		if (window.webkitURL) {
			window.URL = window.webkitURL;
		} else {
			window.URL = {};
			if (window.createBlobURL) {
				window.URL.createObjectURL = function(file) {
					return window.createBlobURL(file);
				};
			} else if (window.createObjectURL) {
				window.URL.createObjectURL = function(file) {
					return window.createObjectURL(file);
				};
			} else {
				//// Dont fail this because it's not absolutely essential
				//// & fails iOS devices (though that might be a good thing in some ways, it
				//// would seriously limit users ability to make quick changes on the go, for instance)
				window.URL.createObjectURL = function(file) {
					return '';
				}
				// throw "File API not supported";
			}
		}
	}

	///////////////////////////// localStorage
	try {
		var i = localStorage.getItem;
	} catch(e) {
		throw "Local Storage not supported"
	}

} catch (e) {
	window.location.href = "/@spontaneous/unsupported?msg=" + window.encodeURI(e);
}

