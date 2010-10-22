console.log("Loading TopBar...")

Spontaneous.TopBar = (function($, S) {
	var dom = S.Dom;

	var RootNode = function(data) {
		var page = data.pages[data.selected];
		this.page = page;
		this.id = page.id;
		this.url = page.url;
		this.title = page.title;
	}
	RootNode.prototype = {
		element: function() {
			var link = $(dom.a, {'href': this.url}).text(this.title).data('page', this.page);
			link.click(function() {
				S.TopBar.set('location', $(this).data('page'));
				return false;
			});
			return link;
		}
	}

	var ChildNode = function(data) {
		var page = data.pages[data.selected];
		this.id = page.id;
		this.url = page.url;
		this.title = page.title;
		this.pages = data.pages;
		this.selected = data.selected;
	}
	ChildNode.prototype = {
		element: function() {
			var select = $(dom.select);
			select.change(function() {
				S.TopBar.set('location', $(this.options[this.selectedIndex]).data('page'));
				return false;
			});
			for (var i = 0, ii = this.pages.length; i < ii; i++) {
				var p = this.pages[i];
				select.append($(dom.option, {'value': p.url, 'selected':(i == this.selected) }).text(p.title).data('page', p))
			};
			return select;
		}
	}
	var top_bar = $.extend({}, S.Properties(), {
		location: "/",
		panel: function() {
			this.wrap = $(dom.div, {'id':'top_bar'});
			this.location = $(dom.div, {'class': 'location'});
			this.mode_switch = $(dom.a, {'class': 'switch-mode'}).
				text(this.opposite_mode(S.ContentArea.mode)).
				click(function() {
					S.TopBar.switch_modes();
			});
			this.wrap.append(this.location);
			this.wrap.append(this.mode_switch);
			return this.wrap;
		},
		init: function() {
			this.set('mode', S.ContentArea.mode);
		},
		switch_modes: function() {
			var m = this.get('mode');
			this.set('mode', this.opposite_mode(m));
			this.mode_switch.text(m);
		},
		opposite_mode: function(to_mode) {
			if (to_mode === 'preview') {
				return 'edit';
			} else if (to_mode === 'edit') {
				return 'preview';
			}
		},
		location_changed: function(new_location) {
			document.title = "Editing: '{title}'".replace("{title}", S.Preview.title());
			console.log("TopBar#location_changed", new_location);
			this.set('location', new_location);
			// this.update_navigation();
		},
		map_changed: function(new_map) {
			this.map = new_map;
			this.update_navigation();
		},
		update_navigation: function() {
			if (this.map) {
				var loc = this.location;
				var path = S.Location.current_path();
				loc.empty();
				for (var i = 0, ii = path.length; i < ii; i++) {
					var p = path[i], node;
					if (p.root) {
						node = new RootNode(p);
					} else {
						node = new ChildNode(p);
					}
					loc.append(node.element());
				}
				var last = path[path.length - 1], next_level = last.pages[last.selected].children;
				if (next_level.length > 0) {
					var select = $(dom.select);
					select.change(function() {
						S.TopBar.set('location', $(this.options[this.selectedIndex]).data('page'));
						return false;
					});
					select.append($(dom.option, {'value': ''}).text(''));
					for (var i = 0, ii = next_level.length; i < ii; i++) {
						var p = next_level[i];
						select.append($(dom.option, {'value': p.url}).text(p.title).data('page', p))
					};
					loc.append(select);
				}
			}
		}
	});
	return top_bar;
})(jQuery, Spontaneous);


