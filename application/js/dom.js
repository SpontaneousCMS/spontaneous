// console.log('Loading DOM...');

Spontaneous.Dom = (function($, S) {
	var tags = 'div p iframe a span strong i img select option label ul li dl dt dd table tr td h1 h2 h3 h4 header input button form textarea optgroup'.split(' ');
	var Dom = {
		body: function() {
			return $(document.body);
		},
		id: function(name) {
			return '#'+name;
		},
		px: function(dim) {
			return dim + 'px';
		},
		cmd_key_label: function(text, key) {
			var cmd = ((window.navigator.platform.indexOf("Mac") === 0) ? "Cmd" : "Ctrl");
			// var alt =  '<span class="key-combo">(' + cmd  + "+"+key+')</span>';
			return this.key_label(text, cmd  + "+" +key);
		},
		key_label: function(text, key) {
			var alt =  '<span class="key-combo">('+key+')</span>';
			return text + " " + alt;
		},
		parse_selector: function(selector) {
			var p, id = '', classes = [], result = {};
			selector = selector || '';
			if (typeof selector === 'string') {
				p = selector.split('.')
			} else if ($.isArray(selector)) {
				p = selector;
			}
			for (var i = 0, ii = p.length; i < ii; i++) {
				var part = p[i];
				if (part === '') {
				} else if (part.indexOf('#') === 0) {
					id = part.substr(1);
				} else if (part.indexOf('.') === 0) {
					var r = this.parse_selector(part);
					classes.push(r['class']);
				} else {
					classes.push(part);
				}
			}
			if (id !== '') {
				result['id'] = id;
			}
			if (classes.length > 0) {
				result['class'] = classes.join(' ')
			}
			return result;
		},
		radio: function(selector, params) {
			var input = this.input(selector, params);
			input.attr('type', 'radio');
			return input;
		}
	};
	var generate = function(tag_name) {
		return function(selector, params) {
			if (typeof selector === 'object') {
				if (!$.isArray(selector)) {
					params = selector;
					selector = '';
				}
			}
			var attrs = $.extend((params || {}), Dom.parse_selector(selector));
			return $(document.createElement(tag_name)).attr(attrs);
		};
	};
	for (var i = 0, ii = tags.length; i < ii; i++) {
		Dom[tags[i]] = generate(tags[i]);
	}
	return Dom;
})(jQuery, Spontaneous);

