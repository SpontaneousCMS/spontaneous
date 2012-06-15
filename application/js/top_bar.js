// console.log("Loading TopBar...")

Spontaneous.TopBar = (function($, S) {
	var dom = S.Dom;

	var RootNode = function(page) {
		this.page = page;
		this.id = page.id;
		this.url = page.url;
		this.title = S.site_domain;
	}
	RootNode.prototype = {
		element: function() {
			var li = dom.li('.root');
			var link = dom.a({'href': this.url}).text(this.title).data('page', this.page);
			link.click(function() {
				var page = $(this).data('page');
				S.Location.load_id(page.id);
				return false;
			});
			li.append(link);
			this.link = link;
			return li;
		},
		set_title: function(new_title) {
			this.link.text(new_title);
		}
	}

	var AncestorNode = function(page) {
		this.page = page;
		this.id = page.id;
		this.title = page.slug;
		this.path = page.path;
	};
	AncestorNode.prototype = {
		element: function() {
			var link = dom.li().append($('<a/>').data('page', this.page).click(function() {
				var page = $(this).data('page');
				S.Location.load_id(page.id);
			}).text(this.title));

			return link;
		}
	};
	var CurrentNode = function(page) {
		var self = this;
		self.page = page;
		self.id = page.id;
		self.path = page.path;
		self.title = page.slug;
		self.pages = page.generation;
	}

	CurrentNode.prototype = {
		element: function() {
			var self = this
			, li = dom.li()
			, select = dom.select()
			, comparator = function(a, b) {
				var at = a.slug, bt = b.slug;
				if (at > bt) { return 1; }
				if (at < bt) { return -1; }
				return 0;
			};
			select.change(function() {
				var page = $(this.options[this.selectedIndex]).data('page');
				S.Location.load_id(page.id);
				return false;
			});

			$.each(this.pages, function(boxname, pages) {
				pages.sort(comparator);
				var optgroup = dom.optgroup().attr('label', boxname);
				for (var i = 0, ii = pages.length; i < ii; i++) {
					var p = pages[i],
					option = dom.option({'value': p.id, 'selected':(p.id == self.id) }).text(p.slug).data('page', p);
					if (p.id === self.id) {
						self.title_option = option;
					}
					optgroup.append(option);
				};
				select.append(optgroup);
			});
			li.append(select);
			return li;
		},
		set_title: function(new_title) {
			this.title_option.text(new_title);
		}
	}

	var ChildrenNode = function(children) {
		this.children = children;
	}

	ChildrenNode.prototype = {
		element: function() {
			var li = dom.li('.children')
			, select = dom.select('.unselected')
			, children = this.children;
			this.li = li;
			this.select = select;
			this.status = dom.option().text(this.status_text());
			select.append(this.status);
			select.change(function() {
				var p = $(this.options[this.selectedIndex]).data('page');
				if (p) {
					S.Location.load_id(p.id());
				}
				return false;
			});
			for (var boxname in children) {
				if (children.hasOwnProperty(boxname)) {
					var optgroup = this.optgroup(boxname), cc = this.sort_children(children[boxname]);
					for (var i = 0, ii = cc.length; i < ii; i++) {
						var p = cc[i];
						optgroup.append(this.option_for_entry(p));
					};
					select.append(optgroup)
				}
			}
			li.append(select);
			return li;
		}.cache(),

		sort_children: function(children) {
			var comparator = function(a, b) {
				var at = a.slug(), bt = b.slug();
				if (at > bt) { return 1; }
				if (at < bt) { return -1; }
				return 0;
			};
			return children.sort(comparator);
		},

		status_text: function() {
			var children = this.children, count = 0;
			for (var boxname in children) {
				if (children.hasOwnProperty(boxname)) { count += children[boxname].length; }
			}
			if (count === 0) {
				this.select.hide();
			} else {
				this.select.show();
			}
			return '('+(count)+' pages)';
		},
		optgroup: function(boxname) {
			return dom.optgroup().attr('label', boxname);
		},
		option_for_entry: function(p) {
			var opt = dom.option({'value': p.id()}).text(p.slug()).data('page', p);
			if (p.watch) {
				p.watch('slug', function(value) {
					opt.text(value);
				}.bind(this));
			}
			return opt;
		},
		update_status: function() {
			this.status.text(this.status_text());
			return this.status;
		},
		add_page: function(page, position) {
			console.log('add_page', page, position)
			var self = this
			, option = self.option_for_entry(page)
			, container = page.container
			, name = container.name()
			, children = self.children
			, optgroup = self.select.find('optgroup[label="'+name+'"]')
			if (optgroup.length === 0) {
				optgroup = this.optgroup(name);
				this.select.append(optgroup);
			}
			optgroup.prepend(option);
			// since the navigation lists are ordered differently from the entries, it's
			// difficult to insert into the right position
			// TODO: re-sort the this.children entries and use this list to find the position in the select

			// happens when we're adding the first item
			if (!children[name]) { children[name] = []; }

			if (position === -1) {
				children[name].push(page)
			} else {
				children[name].splice(position, 0, page)
			}
			self.update_status();
		},

		remove_page: function(page) {
			var self = this
			, container = page.container.name()
			, index = (function(children) {
				for (var boxname in children) {
					if (children.hasOwnProperty(boxname)) {
						var cc = children[boxname];
						for (var i = 0, ii = cc.length; i < ii; i++) {
							if (cc[i].id() === page.id()) { return i; };
						}
					}
				}
			}(self.children))
			, optgroup = this.select.find('optgroup[label="'+container+'"]');
			optgroup.find('option[value="'+page.id()+'"]').remove();
			this.children[container].splice(index, 1);
			this.update_status();
		}
	}

	var PublishButton = new JS.Class({
		rapid_check: 2000,
		normal_check: 10000,
		initialize: function() {
			this.status = false;
			this.set_interval(this.normal_check);
			// this.check_status();
			var update_status = this.update_status.bind(this);
			S.EventSource.addEventListener('publish_progress', function(event) {
				update_status($.parseJSON(event.data))
			});
		},

		check_status: function() {
			S.Ajax.get('/publish/status', this.status_recieved.bind(this));
		},
		status_recieved: function(status, response_code) {
			if (response_code === 'success' && status != this.status) {
				this.update_status(status);
			}
			window.setTimeout(this.check_status.bind(this), this.timer_interval);
		},
		update_status: function(status) {
			if (status === null || status === '') { return; }
			var state = status.state, progress = status.progress
			// if (this.in_progress && (state == this.current_action && progress == this.current_progress)) { return; }
			this.current_action = state;
			this.current_progress = progress;
			if (state === 'complete' || state === 'error') {
				// if (this.in_progress) {
					this.in_progress = false;
					this.progress().stop();
					// this.set_interval(this.normal_check);
					this.set_label("Publish");
					this.button().switchClass('progress', '')
					this.current_action = this.current_progress = null;
				// }
				if (state === 'error') {
					alert('There was a problem publishing: ' + progress)
				}
			} else {
				this.publishing_state();
				// don't turn off intermediate and replace it with an empty progress dial
				// by making sure our progress is > 0 before switching to progress view
				if ((progress !== "*")) {
					this.progress().update(progress);
				} else {
					this.progress().indeterminate();
				}
			}
		},
		publishing_started: function() {
			this.publishing_state();
			this.progress().indeterminate();
		},
		publishing_state: function() {
			// this.set_interval(this.rapid_check);
			this.set_label("Publishing");
			var b = this.button();
			this.current_action = this.current_progress = null;
			if (!b.hasClass('progress')) { b.switchClass('', 'progress'); }
			this.in_progress = true;
		},
		set_label: function(label) {
			if (label !== this._label_text) {
				this._label_text = label;
				this._label.text(label);
			}
		},
		button: function() {
			if (!this._button) {
				this._progress_container = dom.span('#publish-progress');
				this._label = dom.span();
				this._button = dom.a('#open-publish').append(this._progress_container).append(this._label);
				this.set_label("Publish");
				this._button.click(function() {
					if (!this.in_progress) {
						S.Publishing.open_dialogue();
					}
				}.bind(this));
			}
			return this._button
		},
		progress: function() {
			if (!this._progress) {
				this._progress = Spontaneous.Progress('publish-progress', 15, {
					spinner_fg_color: '#ccc',
					progress_fg_color: '#fff'
				});
				this._progress.init();
			}
			return this._progress;
		},
		set_interval: function(milliseconds) {
			this.timer_interval = milliseconds;
		}
	});
	var LocationChildProxy = new JS.Class({
		initialize: function(child) {
			this.child = child;
		},
		id: function() { return this.child.id; },
		title: function() { return this.child.title; },
		slug: function() { return this.child.slug; }
	});

	var CMSNavigationView = new JS.Class({
		initialize: function() {

		},
		panel: function() {
			var self = this;
			if (!self.wrap) {
				self.wrap = dom.div("#cms-navigation-view");
				self.location = dom.ul('#navigation');
				self.mode_switch = dom.a('#switch-mode').
					text(S.TopBar.opposite_mode(S.ContentArea.mode)).
					click(function() {
						S.TopBar.toggle_modes();
					});
				self.publish_button = new PublishButton();
				self.wrap.append(self.location);
				self.wrap.append(self.publish_button.button());
				self.wrap.append(self.mode_switch);
			}
			return self.wrap;
		},
		location_loaded: function(location) {
			var children = {};

			for (var boxname in location.children) {
				if (location.children.hasOwnProperty(boxname)) {
					children[boxname] = [];
					for (var i = 0, cc = location.children[boxname], ii = cc.length; i < ii; i++) {
						children[boxname].push(new LocationChildProxy(cc[i]));
					}
				}
			}
			var children_node = new ChildrenNode(children);
			this.location.append(children_node.element());
			this.children_node = children_node;
		},
		page_loaded: function(page) {
			if (this.children_node) {
				this.children_node.element().remove();
			}
			var children_node = new ChildrenNode(page.children());
			this.location.append(children_node.element());
			page.bind('entry_added', function(entry, position) {
				if (entry.is_page()) {
					children_node.add_page(entry, position);
				}
			});
			page.bind('removed_entry', function(entry) {
				if (entry.is_page()) {
					children_node.remove_page(entry);
				}
			});

			page.watch('slug', function(title) {
				this.navigation_current.set_title(title);
			}.bind(this));

			page.title_field().watch('value', function(title) {
				this.set_browser_title(title);
			}.bind(this));

			this.children_node = children_node;
		},
		update_navigation: function(location) {
			var nodes = [];
			// var location = this.get('location');
			var $location_bar = this.location;
			var ancestors = location.ancestors.slice(0);
			var root, is_root = false, root_node, children_node, current_node;
			if (ancestors.length === 0) {
				root = location;
				is_root = true;
			} else {
				root = ancestors.shift();
			}
			root_node = new RootNode(root);
			nodes.push(root_node);
			for (var i=0, ii=ancestors.length; i < ii; i++) {
				var page = ancestors[i];
				var node = new AncestorNode(page)
				nodes.push(node);
			};
			if (!is_root) {
				current_node = new CurrentNode(location)
				nodes.push(current_node);
			} else {
				current_node = root_node;
			}
			$('li', $location_bar).remove();
			var children_node;
			if (location.children.length > 0) {
				//  children_node = new ChildrenNode(location.children);
				// $location_bar.append(children_node.element())
			}
			for (var i = 0, ii = nodes.length; i < ii; i++) {
				var node = nodes[i];
				$location_bar.append(node.element())
			}
			this.navigation_current = current_node;
		},
		publishing_started: function() {
			this.publish_button.publishing_started();
		},
		mode_set: function(mode) {
			this.mode_switch.text(S.TopBar.opposite_mode(mode));
		},
		hide: function() {
			this.wrap.hide();
		},
		show: function() {
			this.wrap.show();
		}
	});

	var ServiceNavigationView = new JS.Class({
		initialize: function(service) {
			this.service = service;
		},
		panel: function() {
			var self = this;
			this.wrap = dom.div("#service-navigation")
			var title = dom.h2().text(this.service.title);
			var close = dom.a(".button").text("Close").click(function() {
				S.Services.close();
			})
			this.wrap.append(title, close)
			return this.wrap;
		}
	});
	var TopBar = new JS.Singleton({
		include: Spontaneous.Properties,
		location: "/",
		panel: function() {
			this.wrap = dom.div('#top');
			// this.icon = dom.div('#spontaneous-root');
			this.icon = this.rootMenu()
			this.holder = dom.div('#service-outer')
			this.navigationView = new CMSNavigationView();
			this.serviceStation = dom.div("#service-inner");
			this.holder.append(this.navigationView.panel(), this.serviceStation);
			this.wrap.append(this.icon, this.holder);
			return this.wrap;
		},
		rootMenu: function() {
			var li = dom.div('#spontaneous-root').click(function(event) {
				$(this).addClass("active"); // no easy way to remove this
				Spontaneous.Popover.open(event, new Spontaneous.RootMenuView(function() {
					li.removeClass("active");
				}));
			});
			return li.append(dom.span());
		},
		init: function() {
			if (!this.get('mode')) {
				this.set('mode', S.ContentArea.mode);
			}
			S.Editing.watch('page', this.page_loaded.bind(this));
			S.Location.watch('location', this.location_loaded.bind(this));
		},
		location_loaded: function(location) {
			// clear the loaded page so that it forces a reload of the nav when we switch back to edit mode
			this.set('page', undefined);
			this.navigationView.location_loaded(location);
		},
		page_loaded: function(page) {
			var loaded_page = this.get('page'), loaded_id = (loaded_page ? loaded_page.id() : undefined);
			if (page && (page.id() !== loaded_id)) {
				this.set('page', page);
				this.navigationView.page_loaded(page);
			}
		},
		publishing_started: function() {
			this.navigationView.publishing_started();
		},
		set_browser_title: function(page_title) {
			document.title = S.site_domain + " | Editing: '"+page_title+"'";
		},
		location_changed: function(new_location) {
			this.set_browser_title(new_location.title)
			this.set('location', new_location);
			this.navigationView.update_navigation(new_location);
			this.page_loaded = function(page) {
			};
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
		set_mode: function(mode) {
			this.set('mode', mode);
			this.navigationView.mode_set(mode)
		},
		showService: function(service) {
			this.navigationView.hide();
			this.serviceView = new ServiceNavigationView(service);
			this.serviceStation.empty().append(this.serviceView.panel())
		},
		showNavigationView: function() {
			this.serviceStation.empty();
			this.navigationView.show();
		}
	});
	return TopBar;
})(jQuery, Spontaneous);


