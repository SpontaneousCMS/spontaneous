console.log("Loading TopBar...")

Spontaneous.TopBar = (function($, S) {
	var dom = S.Dom;

	var RootNode = function(page) {
		this.page = page;
		this.id = page.id;
		this.url = page.url;
		this.title = page.title;
	}
	RootNode.prototype = {
		element: function() {
			var li = $(dom.li, {'class':'root'});
			var link = $(dom.a, {'href': this.url}).text(this.title).data('page', this.page);
			link.click(function() {
				var page = $(this).data('page');
				S.Location.load_id(page.id);
				return false;
			});
			li.append(link);
			return li;
		}
	}

	var AncestorNode = function(page) {
		this.page = page;
		this.id = page.id;
		this.title = page.title;
		this.path = page.path;
	};
	AncestorNode.prototype = {
		element: function() {
			var link = $(dom.li).append($('<a/>').data('page', this.page).click(function() {
				var page = $(this).data('page');
				S.Location.load_id(page.id);
			}).text(this.title));
			
			return link;
		}
	};
	var CurrentNode = function(page) {
		this.page = page;
		this.id = page.id;
		this.path = page.path;
		this.title = page.title;
		this.pages = page.generation.sort(function(p1, p2) {
			var a = p1.title, b = p2.title;
			if (a == b) return 0;
			return (a < b ? -1 : 1);
		});
		for (var i = 0, ii = this.pages.length; i < ii; i++) {
			var p = this.pages[i];
			if (p.id === this.id) {
				this.selected = i;
				break;
			}
		}
	}

	CurrentNode.prototype = {
		element: function() {
			var li = $(dom.li);
			var select = $(dom.select);
			select.change(function() {
				var page = $(this.options[this.selectedIndex]).data('page');
				S.Location.load_id(page.id);
				return false;
			});
			for (var i = 0, ii = this.pages.length; i < ii; i++) {
				var p = this.pages[i];
				select.append($(dom.option, {'value': p.id, 'selected':(i == this.selected) }).text(p.title).data('page', p))
			};
			li.append(select);
			// select.hide();
			// var link = $(dom.li).append($('<a/>').data('page', this.page).click(function() {
			// 	// var page = $(this).data('page');
			// 	// S.Location.load_id(page.id);
			// 	select.toggle().trigger('click');
			// }).text(this.title));
			// 
			// link.append(select);
			// return link;
			return li;
		}
	}

	var ChildrenNode = function(children) {
		this.children = children.sort(function(p1, p2) {
			var a = p1.title, b = p2.title;
			if (a == b) return 0;
			return (a < b ? -1 : 1);
		});
	}

	ChildrenNode.prototype = {
		element: function() {
			var li = $(dom.li);
			var select = $(dom.select, {'class':'unselected'});
			select.append($(dom.option).text('('+(this.children.length)+' pages)'));
			select.change(function() {
				var p = $(this.options[this.selectedIndex]).data('page');
				if (p) {
					S.Location.load_id(p.id);
				}
				return false;
			});
			for (var i = 0, ii = this.children.length; i < ii; i++) {
				var p = this.children[i];
				select.append($(dom.option, {'value': p.id}).text(p.title).data('page', p))
			};
			li.append(select);
			return li;
		}
	}

	var TopBar = new JS.Singleton({
		include: Spontaneous.Properties,
		location: "/",
		panel: function() {
			this.wrap = $(dom.div, {'id':'top'});
			this.location = $(dom.ul, {'id': 'navigation'});
			this.location.append($(dom.li).append($(dom.a)))
			this.mode_switch = $(dom.a, {'class': 'switch-mode'}).
				text(this.opposite_mode(S.ContentArea.mode)).
				click(function() {
					S.TopBar.toggle_modes();
			});
			this.wrap.append(this.location);
			this.wrap.append(this.mode_switch);
			return this.wrap;
		},
		init: function() {
			if (!this.get('mode')) {
				this.set('mode', S.ContentArea.mode);
			}
		},
		set_mode: function(mode) {
			this.set('mode', mode);
			this.mode_switch.text(this.opposite_mode(mode));
		},
		toggle_modes: function() {
			this.set_mode(this.opposite_mode(this.get('mode')));
		},
		opposite_mode: function(to_mode) {
			if (to_mode === 'preview') {
				return 'edit';
			} else if (to_mode === 'edit') {
				return 'preview';
			}
		},
		location_changed: function(new_location) {
			document.title = "Editing: '{title}'".replace("{title}", new_location.title);
			this.set('location', new_location);
			this.update_navigation();
		},
		update_navigation: function() {
			var nodes = [];
			var location = this.get('location');
			var ancestors = location.ancestors;
			var root, is_root = false;
			if (ancestors.length === 0) {
				root = location;
				is_root = true;
			} else {
				root = ancestors.shift();
			}
			nodes.push(new RootNode(root));
			for (var i=0, ii=ancestors.length; i < ii; i++) {
				var page = ancestors[i];
				var node = new AncestorNode(page)
				nodes.push(node);
			};
			if (!is_root) {
				nodes.push(new CurrentNode(location));
			}
			if (location.children.length > 0) {
				nodes.push(new ChildrenNode(location.children));
			}
			$('li:gt(0)', this.location).remove();
			// this.location.empty();
			for (var i = 0, ii = nodes.length; i < ii; i++) {
				var node = nodes[i];
				this.location.append(node.element())
			}
		}
	});
	return TopBar;
})(jQuery, Spontaneous);


