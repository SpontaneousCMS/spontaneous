// console.log("Loading PageBrowser...");


Spontaneous.PageBrowser = (function($, S) {
	var dom = S.Dom;
	var PageBrowser = new JS.Class(Spontaneous.PopoverView, {
		initialize: function(origin) {
			origin = String(origin || "");
			if (/^\//.test(origin)) {
				this.origin = origin || '/';
				this.selected = this.origin;
			} else {
				this.selected = false;
				this.origin = '/';
			}
			this.page_list = this.origin_list();
			this.ancestor_list = this.origin_ancestors();

		},
		origin_list: function() {
			return function(location) {
				return location.generation;
			}
		},
		children_list: function() {
			return function(location) {
				return location.children;
			}
		},
		origin_ancestors: function() {
			return function(location) {
				return location.ancestors;
			}
		},
		children_ancestors: function() {
			return function(location) {
				return location.ancestors.concat(location);
			}
		},
		get_page_list: function() {
			var path;
			if (typeof this.origin === 'string') {
				path = '/location' + this.origin;
			} else {
				path = '/map/' + this.origin.id;
			}
			S.Ajax.get(path, this, this.page_list_loaded);
		},
		view: function() {
			var wrapper = dom.div('.page-browser'), table = dom.div('.page-list');
			ancestors = dom.div('.page-ancestors');
			wrapper.append(ancestors).append(table);
			this.wrapper = wrapper;
			this.table = table;
			this.ancestors = ancestors;
			this.get_page_list();
			return wrapper;
		},
		page_list_loaded: function(page_list, status) {
			if (status === 'success') {
				this.table.empty();
				this.location = page_list;
				this.manager.page_list_loaded(this);
				var g = this.page_list(this.location), table = this.table;
				for (var i = 0, ii = g.length; i < ii; i++) {
					var page = g[i];
					table.append(this.get_entry(page));
				}

				this.ancestors.empty();
				var _browser = this, list = dom.ul(), ancestors = this.ancestor_list(this.location);

				this.depth = ancestors.length;
				var click = function(p) {
					return function(event) {
						_browser.ancestor_selected(p);
						return false;
					};
				};

				for (var i = 0, ii = ancestors.length; i < ii; i++) {
					var a = ancestors[i], li = dom.li().append(dom.a().text(a.title)).append(dom.span().text("/")).click(click(a));
					list.append(li);
				}
				if (ancestors.length === 0) {
					list.append(dom.li().append(dom.a().text('Choose a page...')))
				}
				this.ancestors.append(list);
			}
		},
		get_entry: function(page) {
			var _browser = this, selected = function(p) {
				return function() {
					_browser.page_selected(p);
					$(this).addClass('active');
				};
			};
			var next_click = function() {
				_browser.next_level(page);
				return false;
			}

			var row = dom.div('.page').click(selected(page)), title = dom.a().text(page.title);
			if (page.children > 0) {
				var next = dom.span()
				next.click(next_click);
				row.append(next);
			}
			row.append(title);
			if (this.selected && (page.path === this.selected)) {
				row.addClass('active');
			}
			return row;
		},
		ancestor_selected: function(page) {
			this.page_list = this.origin_list();
			this.ancestor_list = this.origin_ancestors();
			this.origin = page;
			this.get_page_list();
		},
		next_level: function(page) {
			this.page_list = this.children_list();
			this.ancestor_list = this.children_ancestors();
			this.origin = page;
			this.get_page_list();
			// this.manager.next_level(page);
		},
		page_selected: function(page) {
			var table = this.table;
			$('.page', table).removeClass('active');
			this.selected = page.path;
			this.manager.page_selected(page);
		},
		title: function() {
			return "Choose Page";
		},
		width: function() {
			return 400;
		},
		// position_from_event: function(event) {
		// 	return {top: event.clientX, left: event.clientY};
		// },
	});
	return PageBrowser;
})(jQuery, Spontaneous);


