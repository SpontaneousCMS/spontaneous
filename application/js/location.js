console.log("Loading Location...")

Spontaneous.Location = (function($, S) {
	var ajax = S.Ajax;
	var location = $.extend({}, Spontaneous.Properties(), {
		init: function() {
			ajax.get('/map', this, this.location_loaded);
		},
		load_map: function() {
		},
		location_loaded: function(location) {
			this.set('location', location);
			console.log("Location#location_loaded", location);
		},
		load_path: function(path) {
			console.log("Loading path", path);
			this.find(path);
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
		find: function(path) {
			if (this.location() && path === this.location().path) {
				return this.location();
			}
			ajax.get('/location'+path, this, this.location_loaded);
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


