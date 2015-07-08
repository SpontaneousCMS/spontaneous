// console.log('Loading Page...')

Spontaneous.Page = (function($, S) {
	var dom = S.Dom, user = S.User;

	var Page = new JS.Class(Spontaneous.Content, {
		initialize: function(content) {
			this.callSuper(content);
			this.set('path', content.path);
		},

		save_complete: function(values) {
			this.callSuper(values);
			this.set('slug', values.slug);
			this.set('path', values.path);
		},

		is_root: function() {
			return (this.get('path') === '/');
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
		// annoyingly duplicating the version coming from the server, which is
		// a hash of box_name => [box_entries]
		children: function() {
			var _children = {};
			for (var i = 0, entries = this.entries(), ii = entries.length; i < ii; i++) {
				var e = entries[i], container = e.container, container_name = container.name();
				if (e.is_page()) {
					_children[container_name] = (_children[container_name] || []);
					_children[container_name].push(e);
				}
			}
			return _children;
		},

		contentVisibilityToggle: function(affected) {
			this.boxes().forEach(function(box) {
				box.contentVisibilityToggle(affected);
			});
		}

	});

	return Page;
}(jQuery, Spontaneous));

Spontaneous.page = function() {
	return Spontaneous.Editing.get('page');
};

Spontaneous.set_browser_title = function(page_title) {
	document.title = Spontaneous.site_domain + " | Editing: '"+page_title+"'";
};
