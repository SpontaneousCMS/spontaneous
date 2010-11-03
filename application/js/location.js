console.log("Loading Location...")

Spontaneous.Location = (function($, S) {
	var ajax = S.Ajax;
	var location = $.extend({}, Spontaneous.Properties(), {

		init: function(callback) {
			var complete = (function(location) {
				return function() {
					callback();
					location.location_loaded();
				};
			})(this);
			ajax.get('/map', this, complete);
		},
		load_map: function() {
		},
		location_loaded: function(location) {
			console.log("Location#location_loaded", location);
			this.set('location', location);
		},
		load_id: function(id) {
			console.log("Loading id", id);
			this.find_id(id);
		},
		load_path: function(path) {
			console.log("Loading path", path);
			this.find_path(path);
		},
		url: function() {
			var l = this.location();
			return (l ? l.url : "/");
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
			ajax.get('/location'+path, this, this.location_loaded);
		},
		find_id: function(id) {
			if (this.location() && id === this.location().id) {
				return this.location();
			}
			ajax.get('/map/'+id, this, this.location_loaded);
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
		}
	});
	return location;
})(jQuery, Spontaneous);


