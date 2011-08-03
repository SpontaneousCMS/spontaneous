// console.log('Loading Page...')

Spontaneous.Page = (function($, S) {
	var dom = S.Dom, user = S.User;

	var Page = new JS.Class(Spontaneous.Content, {
		initialize: function(content) {
			this.callSuper(content);
			this.set('path', content.path);
		},

		save_complete: function(values) {
			this.callSuper(values)
			this.set('slug', values.slug);
			this.set('path', values.path);
		},
		depth: function() {
			// depth in this case refers to content depth which is always 0 for pages
			return 0;
		},
		entries: function() {
			var _entries = [];
			for (var i = 0, boxes = this.boxes(), ii = boxes.length; i < ii; i++) {
				var box = boxes[i];
				_entries = _entries.concat(box.entries());
			}
			return _entries;
		},
		children: function() {
			var _children = [];
			for (var i = 0, entries = this.entries(), ii = entries.length; i < ii; i++) {
				var e = entries[i];
				if (e.is_page()) {
					_children.push(e);
				}
			}
			return _children;
		}

	});

	return Page;
}(jQuery, Spontaneous));
