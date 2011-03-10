// console.log('Loading DOM...');

Spontaneous.Dom = (function($, S) {
	var tags = 'div p iframe a span img select option label ul li dl dt dd table tr td h1 h2 h3 h4 header input button form textarea'.split(' ');
	var Dom = {
		body: function() {
			return $(document.body);
		},
		id: function(name) {
			return '#'+name;
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
		}
	};
	var generate = function(tag_name) {
		var tag = '<'+tag_name+'/>';
		return function(selector, params) {
			if (typeof selector === 'object') {
				if (!$.isArray(selector)) {
					params = selector;
					selector = '';
				}
			}
			var attrs = $.extend((params || {}), Dom.parse_selector(selector));
			return $(tag, attrs);
		};
	};
	for (var i = 0, ii = tags.length; i < ii; i++) {
		Dom[tags[i]] = generate(tags[i]);
	}
	return Dom;
})(jQuery, Spontaneous);

