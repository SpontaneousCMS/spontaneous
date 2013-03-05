// console.log("Loading Location...")

Spontaneous.Location = (function($, S) {
	var ajax = S.Ajax;

	var State = new JS.Class({
		initialize: function(path) {
			this.page_id = false;
			this.mode = null;
			if (path) {
				path = path.substr(ajax.namespace.length+1);
				this.parse_path(path);
			}
		},
		parse_path: function(path) {
			var areas = path.split('/'), id = areas[0], mode = areas[1];
			this.page_id = id;
			this.mode = mode;
		},
		restore: function() {
			if (this.mode) {
				Spontaneous.Location.view_mode_changed(this.mode)
				Spontaneous.TopBar.set_mode(this.mode)
			}
			if (this.page_id) {
				Spontaneous.Location.load_id(this.page_id);
			} else {
				Spontaneous.Location.load_path('/');
			}
		},
		to_hash: function() {
			return '#/'+(this.page_id || '') + (this.mode ? ('@' + this.mode) : '');
		},
		to_path: function() {
			return [ajax.namespace, (this.page_id || ''), this.mode].join("/")
		},
		to_obj: function() {
			return {
				page_id: this.page_id,
				mode: this.mode
			}
		}
	});

	State.extend({
		// currently just produces some kind of loop
		popstate: function(event) {
			State.restore(event)
			return false;
		},
		restore: function(event) {
			var state = new State(window.location.pathname)
			state.restore();
		},

		page: function(location, mode) {
			var s = new State
			s.page_id = location.id;
			s.mode = mode;
			window.history.replaceState(s.to_obj(), ''+s.page_id, s.to_path());
		}
	});

	var Location = new JS.Singleton({
		include: Spontaneous.Properties,
		init: function(callback) {
			this.locationCache = {};
			callback();
			State.restore();
			// $(window).bind('hashchange', State.restore);
		},
		page_loaded: function(page) {
			// page.watch('slot', this, 'slot_changed');
		},
		slot_changed: function(slot) {
			// console.log('Location.slot_changed', slot, slot.uid(), slot.container.id());
		},
		view_mode_changed: function(mode) {
			this.set('view_mode', mode);
			if (this.get('location')) {
				this.update_state(this.get('location'), mode);
			}
		},
		load_map: function() {
		},
		location_loaded: function(location, status, xhr) {
			if (xhr.status === 406) { // Code returned if site is missing a root page
				var d = new Spontaneous.AddHomeDialogue(Spontaneous.Types.get('types'));
				d.open();
			} else {
				this.set('location', location);
				// HACK: see preview.js (Preview.display)
				this.set('path', location.path);
				this.update_state(location, this.get('view_mode'));
			}
		},
		update_state: function(location, mode) {
			State.page(location, mode);
		},
		load_id: function(id) {
			var l = this.location();
			if (!l || id != l.id) {
				this.find_id(id);
			}
		},
		load_path: function(path) {
			this.find_path(path);
		},
		path_changed: function(path) {
			this.set('path', path);
		},
		url: function() {
			var l = this.location();
			return (l ? l.url : "/about");
		},
		location: function() {
			return this.get('location');
		},
		update: function(location) {
			this.set('location', location);
			this.path_from_url(location.url)
		},
		current_path: function() {
			return this.path_from_url(this.url());
		},
		find_path: function(path) {
			if (this.location() && path === this.location().path) {
				return this.location();
			}
			this.retrieve('/map/path'+path, this.location_loaded.bind(this));
		},
		find_id: function(id) {
			if (this.location() && id === this.location().id) {
				return this.location();
			}
			this.retrieve('/map/'+id, this.location_loaded.bind(this));
		},
		path_from_url: function(url) {
			var map = this.get('map'),
			children = map.children,
			path = [], i, ii,
			parts = url.split('/').slice(1), position = 0;
			// add root to path
			path.push({selected:0, pages:[ map ], root:true});;
			while (position < parts.length) {
				for (i = 0, ii = children.length; i < ii; i++) {
					var child = children[i], slug = child.url.split('/').slice(-1)[0];
					if (slug === parts[position]) {
						path.push({selected:i, pages: children});
						children = child.children;
						break;
					}
				}
				position += 1;
			}
			return path;
		},
		retrieve: function(url, callback) {
			ajax.get(url, {}, callback, {ifModified: true, cache: true});
		},
		lastModified: function(path) {
			return (this.locationCache[path] || {}).lastModified;
		},
		setLocationCache: function(path, lastModified, location) {
			this.locationCache[path] = { lastModified: lastModified, location: location };
		},
		getLocationCache: function(path) {
			return this.locationCache[path].location;
		}
	});
	// $(window).bind('popstate', State.popstate);
	return Location;
})(jQuery, Spontaneous);

