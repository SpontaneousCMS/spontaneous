console.log("Loading PageBrowser...");


Spontaneous.PageBrowser = (function($, S) {
	var dom = S.Dom;
	var PageBrowser = new JS.Class(Spontaneous.PopoverView, {
		initialize: function(origin) {
			this.origin = origin || '/';
			this.page_source = this.origin_source();
			console.log('PageBrowser for', [this.origin]);

			// origin could be path or page object (?)
		},
		origin_source: function() {
			return function(location) {
				return location.generation;
			}
		},
		children_source: function() {
			return function(location) {
				return location.children;
			}
		},
		get_page_list: function() {
			var path;
			console.log(typeof origin);
			if (typeof this.origin === 'string') {
				path = '/location' + this.origin;
			} else {
				path = '/map/' + this.origin.id;
			}
			S.Ajax.get(path, this, this.page_list_loaded);
		},
		view: function() {
			var wrapper = $(dom.div, {'class':'page-browser'}), table = $(dom.div, {'class':'page-list'});
			wrapper.append(table);
			this.wrapper = wrapper;
			this.table = table;
			this.get_page_list();
			return wrapper;
		},
		page_list_loaded: function(page_list, status) {
			if (status === 'success') {
				this.table.empty();
				console.log(status, page_list)
				this.location = page_list;
				this.manager.page_list_loaded(this);
				var g = this.page_source(this.location), table = this.table;
				for (var i = 0, ii = g.length; i < ii; i++) {
					var page = g[i];
					table.append(this.get_entry(page));
				}
			}
		},
		get_entry: function(page) {
			var _browser = this, selected = function(p) {
				return function() {
					_browser.page_selected(p);
					$(this).addClass('active');
				};
			};
			var next = function() {
				_browser.next_level(page);
			}

			var row = $(dom.div, {'class':'page'}).click(selected(page)), title = $(dom.a).text(page.title);
			row.append(title)
			if (page.children > 0) {
				var next = $(dom.span).text('>').click(next)
				row.append(next);
			}
			if (page.id === this.location.id) {
				row.addClass('active');
			}
			return row;
		},
		next_level: function(page) {
			this.page_source = this.children_source();
			this.origin = page;
			this.get_page_list();
			// this.manager.next_level(page);
		},
		page_selected: function(page) {
			var table = this.table;
			$('.page', table).removeClass('active');
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


