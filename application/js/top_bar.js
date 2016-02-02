// console.log("Loading TopBar...")

Spontaneous.TopBar = (function($, S) {
	var dom = S.Dom, Ajax = S.Ajax;

	var disableParent = function(el) {
		el.hover(function() {
			$(this).parent().addClass('disabled');
		}, function() {
			$(this).parent().removeClass('disabled');
		});
		return el;
	};

	var slugComparator = function(a, b) {
		var at = a.slug, bt = b.slug;
		if (at > bt) { return 1; }
		if (at < bt) { return -1; }
		return 0;
	};

	var RootBrowser = new JS.Class(Spontaneous.PopoverView, {
		initialize: function(roots) {
			this.roots = roots;
		},
		width: function() { return 300; },
		title: function() { return 'Choose Root'; },
		view: function() {
			var self = this
			, w = dom.div('#navigation-page-browser.pop-root-browser')
			, list = dom.div('.pages')
			, roots = this.roots.roots;
			var click = function(page_id) {
				return function() { self.close(); S.Location.load_id(page_id); };
			};
			for (var key in roots) {
				if (roots.hasOwnProperty(key)) {
					var r = dom.div('.page').text(key).click(click(roots[key]));
					list.append(r);
				}
			}
			w.append(list);
			this.wrapper = w;
			return w;
		}
	});

	var PageBrowser = new JS.Class(Spontaneous.PopoverView, {
		initialize: function(origin, pages) {
			this.origin = origin;
			this.pages = pages;
		},
		width: function() { return 300; },
		title: function() { return 'Go to Page'; },
		view: function() {
			var self = this, w = dom.div('#navigation-page-browser.pop-root-browser')
			, list = dom.div('.pages')
			, frame = dom.div('.frame')
			, searchArea = dom.div('.search')
			, searchInput = dom.input({type: 'search', placeholder:'Search'});
			searchArea.append(searchInput);
			searchInput.bind('change keyup search', self.updateSearch.bind(self, searchInput));
			self.wrapper = w;
			self.list = list;
			frame.append(list);
			w.append(searchArea, frame);
			this.loadPages();
			return w;
		},
		updateSearch: function(input) {
			if (!this.pages) { return; }

			var self = this, boxes = {}, query = input.val(), search = new RegExp(query, 'i');
			// need to bubble up the event if the query is identical as this event
			// is also triggered on input blur when a page is clicked.
			if (query === this.query) {
				return true;
			}

			this.query = query;
			if (query === '') {
				self.listPages(this.pages);
				return;
			}
			$.each(self.pages, function(boxname, pages) {
				var box = [];
				for (var i = 0, ii = pages.length; i < ii; i++) {
					var page = pages[i];
					if (search.test(page.slug) || search.test(page.title)) {
						box.push(page);
					}
				}
				if (box.length > 0) {
					boxes[boxname] = box;
				}
			});
			self.listPages(boxes, query);
		},
		clearList: function() {
			this.list.empty();
		},
		loadPages: function() {
			if (this.pages) {
				this.listPages(this.pages);
			} else {
				var path = ['/map', this.origin.id].join('/');
				S.Location.retrieve(path, this.pagesLoaded.bind(this));
			}
		},
		pagesLoaded: function(pages) {
			this.pages = pages.generation;
			this.listPages(pages.generation);
		},
		listPages: function(generation, filter) {
			var self = this, origin = self.origin, load_page = function(p) {
				return function() {
					self.close();
					S.Location.load_id(p.id);
				};
			};
			self.clearList();
			if (Object.keys(generation).length === 0) {
				var msg = filter ? 'No matches for ‘'+filter+'’' : 'No pages';
				self.list.append(dom.h3().text(msg));
				return;
			}
			$.each(generation, function(boxname, pages) {
				pages.sort(slugComparator);
				var box = dom.div('.box').append(dom.h4().text(boxname));
				for (var i = 0, ii = pages.length; i < ii; i++) {
					var p = pages[i], page = dom.div('.page').text(p.slug).data('page', p);
					if (origin && p.id === origin.id) {
						page.addClass('current');
					}
					page.click(load_page(p));
					box.append(page);
				}
				self.list.append(box);
			});
		}
	});

	var RootNode = function(page, roots) {
		this.page = page;
		this.roots = roots;
		this.id = page.id;
		this.url = page.url;
		this.title = this.title(); //page.title; //S.site_domain;
	};
	RootNode.prototype = {
		title: function() {
			var roots = this.roots.roots;

			for (var key in roots) {
				if (roots.hasOwnProperty(key)) {
					if (roots[key] === this.id) { return key; }
				}
			}
			return S.site_domain;
		},
		element: function() {
			var self = this, li = dom.li('.root-node');
			var link = dom.a({'href': this.url}).text(this.title).data('page', this.page);
			if (Object.keys(this.roots.roots).length === 1) {
				li.addClass('singluar');
			} else {
				li.click(function(event) {
					var browser = new RootBrowser(self.roots);
					Spontaneous.Popover.open(event, browser);
				});
			}
			var loaded = S.Location.get('location')
			, active = (loaded.id == this.page.id) // active == true represents the state where the currently shown page is this node
			;
			if (!active) {
				link.click(function() {
					var page = $(this).data('page');
					S.Location.load_id(page.id);
					return false;
				});
			}
			disableParent(link);
			li.append(link);
			this.link = link;
			return li;
		},
		set_title: function(new_title) {
			this.link.text(new_title);
		}
	};

	var AncestorNode = function(page) {
		this.page = page;
		this.id = page.id;
		this.title = page.slug;
		this.path = page.path;
	};
	AncestorNode.prototype = {
		element: function() {
			var page = this.page, li = dom.li('.ancestor-node'), link = $('<a/>').data('page', page).click(function() {
				var page = $(this).data('page');
				S.Location.load_id(page.id);
				return false;
			}).text(this.title);

			disableParent(link);
			li.append(link);

			li.click(function(e) {
				var browser = new PageBrowser(page);
				Spontaneous.Popover.open(e, browser);
				e.preventDefault();
				return false;
			});

			return li;
		}
	};
	var CurrentNode = function(page) {
		var self = this;
		self.page = page;
		self.id = page.id;
		self.path = page.path;
		self.title = page.slug;
		self.pages = page.generation;
	};

	CurrentNode.prototype = {
		element: function() {
			var self = this
, li = dom.li('.current-node')
			, link = dom.a().text(self.title);
			li.click(function(event) {
				var browser = new PageBrowser(self.page, self.pages);
				Spontaneous.Popover.open(event, browser);
				return false;
			});
			li.append(link);
			this.title_element = link;
			return li;
		},
		set_title: function(new_title) {
			this.title_element.text(new_title);
		}
	};

	var ChildrenNode = function(origin) {
		this.origin = origin;
	};

	ChildrenNode.prototype = {
		element: function() {
			var self = this, li = dom.li('.children'), link = dom.a('.unselected'), children = this.children;
			this.li = li;
			this.link = link.text(this.status_text());
			li.append(link);
			li.click(function(event) {
				var browser = new PageBrowser(self.origin, self.children());
				Spontaneous.Popover.open(event, browser);
				return false;
			});
			return li;
		}.cache(),

		each: function(block) {
			var self = this, children = this.origin.children;
			for (var boxname in children) {
				if (children.hasOwnProperty(boxname)) {
					for (var i = 0, box = children[boxname], ii = box.length; i < ii; ++i) {
						block(box[i]);
					}
				}
			}
		},
		children: function() {
			return this.origin.children;
		},

		status_text: function() {
			var children = this.origin.children, count = 0;
			for (var boxname in children) {
				if (children.hasOwnProperty(boxname)) { count += children[boxname].length; }
			}
			if (count === 0) {
				this.li.hide();
			} else {
				this.li.show();
			}
			return '('+(count)+' page'+(count === 1 ? '' : 's')+')';
		},
		update_status: function() {
			this.link.text(this.status_text());
			return this.link;
		},
		add_page: function(page, position) {
			var self = this
, container = page.container
, name = container.name()
			, children = self.origin.children
, box = children[name];

			if (!box) {
				box = [];
				self.origin.children[name] = box;
			}
			// make the new entry as much like the originals as possible
			var entry = {
				id: page.id(),
				children: 0,
				slug: page.slug(),
				title: page.title(),
				type_id: page.content.type_id
			};
			box.push(entry);
			self.update_status();
		},

		remove_page: function(page) {
			var self = this
, children = self.origin.children
, container = page.container.name()
			, page_id = page.id()
			, index = (function(children) {
				for (var boxname in children) {
					if (children.hasOwnProperty(boxname)) {
						var cc = children[boxname];
						for (var i = 0, ii = cc.length; i < ii; i++) {
							if (cc[i].id === page_id) { return i; }
						}
					}
				}
			}(children));
			children[container].splice(index, 1);
			self.update_status();
		}
	};

	var PublishButton = new JS.Class({
		rapid_check: 2000,
		normal_check: 10000,
		initialize: function() {
			this.status = false;
			this.disabled = true;
			this.set_interval(this.normal_check);
			var update_status = this.update_status.bind(this);
			S.EventSource.addEventListener('publish_progress', function(event) {
				update_status($.parseJSON(event.data));
			});
		},
		user_loaded: function(user) {
			if (user.can_publish()) {
				this.disabled = false;
				this.button().removeClass('disabled').velocity('fadeIn');
			}
		},
		update_status: function(status) {
			if (status === null || status === '') { return; }
			var state = status.state, progress = status.progress;
			// if (this.in_progress && (state == this.current_action && progress == this.current_progress)) { return; }
			this.current_action = state;
			this.current_progress = progress;
			if (state === 'complete' || state === 'error') {
				// if (this.in_progress) {
					this.in_progress = false;
					this.progress().stop();
					// this.set_interval(this.normal_check);
					this.set_label('Publish');
					this.button().switchClass('progress', '');
					this.current_action = this.current_progress = null;
				// }
				if (state === 'error') {
					alert('There was a problem publishing: ' + progress);
				}
			} else {
				this.publishing_state();
				// don't turn off intermediate and replace it with an empty progress dial
				// by making sure our progress is > 1 before switching to progress view
				if ((progress === '*') || (progress < 1.0)) {
					this.progress().indeterminate();
				} else {
					this.progress().update(progress);
				}
			}
		},
		publishing_started: function() {
			this.publishing_state();
			this.progress().indeterminate();
		},
		publishing_state: function() {
			// this.set_interval(this.rapid_check);
			this.set_label('Publishing');
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
				this._button = dom.a('#open-publish.disabled').append(this._progress_container).append(this._label).hide();
				this.set_label('Publish');
				this._button.click(function() {
					if (!this.disabled && !this.in_progress) {
						S.Publishing.open_dialogue();
					}
				}.bind(this));
			}
			return this._button;
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
		initialize: function(topBar) {
			this.topBar = topBar;
		},
		panel: function() {
			var self = this;
			if (!self.wrap) {
				self.wrap = dom.div('#cms-navigation-view');
				self.location = dom.ul('#navigation');
				self.mode_switch = dom.a('#switch-mode').
					text(S.TopBar.opposite_mode(S.ContentArea.mode)).
					click(function() {
						S.TopBar.toggle_modes(self.previewModeDisabled);
					});

				self.publish_button = new PublishButton();
				self.wrap.append(self.location);
				self.wrap.append(self.publish_button.button());
				self.wrap.append(self.mode_switch);
				S.User.watch('user', function(user) { self.publish_button.user_loaded(user); });
			}
			return self.wrap;
		},
		roots: function(roots) {
			this.roots = roots;
		},
		location_loaded: function(location) {
			var self = this;
			var children_node = new ChildrenNode(location);
			self.location.append(children_node.element());
			self.children_node = children_node;
		},
		page_loaded: function(page) {
			var self = this, children_node = self.children_node;

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

			if (!page.is_root()) {
				page.watch('slug', function(title) {
					self.navigation_current.set_title(title);
				});
			}

			page.title_field().watch('value', function(title) {
				Spontaneous.set_browser_title(title);
			});
		},
		update_navigation: function(location) {
			var nodes = [];
			// var location = this.get('location');
			var $location_bar = this.location;
			if (typeof location.ancestors === 'undefined') {
				console.warn('Invalid location', location);
				return;
			}
			var ancestors = location.ancestors.slice(0);
			var i, node, root, is_root = false, root_node, children_node, current_node;
			if (ancestors.length === 0) {
				root = location;
				is_root = true;
			} else {
				root = ancestors.shift();
			}
			root_node = new RootNode(root, this.roots);
			nodes.push(root_node);
			for (i=0, ii=ancestors.length; i < ii; i++) {
				var page = ancestors[i];
				node = new AncestorNode(page);
				nodes.push(node);
			}
			if (!is_root) {
				current_node = new CurrentNode(location);
				nodes.push(current_node);
			} else {
				current_node = root_node;
			}
			$('li', $location_bar).remove();

			if (location.children.length > 0) {
				//  children_node = new ChildrenNode(location.children);
				// $location_bar.append(children_node.element())
			}
			for (i = 0, ii = nodes.length; i < ii; i++) {
				node = nodes[i];
				$location_bar.append(node.element());
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
			this.wrap = dom.div('#service-navigation');
			var title = dom.h2().text(this.service.title);
			var close = dom.a('.button').text('Close').click(function() {
				S.Services.close();
			});
			this.wrap.append(title, close);
			return this.wrap;
		}
	});
	var TopBar = new JS.Singleton({
		include: Spontaneous.Properties,
		location: '/',
		panel: function() {
			this.wrap = dom.div('#top');
			// this.icon = dom.div('#spontaneous-root');
			this.icon = this.rootMenu();
			this.holder = dom.div('#service-outer');
			this.navigationView = new CMSNavigationView(this);
			this.serviceStation = dom.div('#service-inner');
			this.holder.append(this.navigationView.panel(), this.serviceStation);
			this.wrap.append(this.icon, this.holder);
			return this.wrap;
		},
		rootMenu: function() {
			var li = dom.div('#spontaneous-root').click(function(event) {
				$(this).addClass('active'); // no easy way to remove this
				Spontaneous.Popover.open(event, new Spontaneous.RootMenuView(function() {
					li.removeClass('active');
				}));
			});
			return li.append(dom.span());
		},
		init: function(metadata) {
			if (!this.get('mode')) {
				this.set('mode', S.ContentArea.mode);
			}
			this.navigationView.roots(metadata.roots);
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
		location_changed: function(new_location) {
			Spontaneous.set_browser_title(new_location.title);
			this.set('location', new_location);
			this.navigationView.update_navigation(new_location);
			this.page_loaded = function(page) {
			};
		},
		toggle_modes: function(previewModeDisabled) {
			var newMode = this.opposite_mode(this.get('mode'));
			if (previewModeDisabled && newMode === 'preview') {
				return;
			}
			this.set_mode(newMode);
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
			this.navigationView.mode_set(mode);
		},
		showService: function(service) {
			this.navigationView.hide();
			this.serviceView = new ServiceNavigationView(service);
			this.serviceStation.empty().append(this.serviceView.panel());
		},
		showNavigationView: function() {
			this.serviceStation.empty();
			this.navigationView.show();
		}
	});
	return TopBar;
}(jQuery, Spontaneous));
