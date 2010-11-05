console.log('Loading Types...');

Spontaneous.Types = (function($, S) {
	var ajax = S.Ajax, type_map = {};
	var Type = function(type_data) {
		this.data = type_data;
		this.type = type_data.type;
		this.title = type_data.title;
		this.field_prototypes = {};
		var fields = this.data.fields;
		for (var i = 0, ii = fields.length; i < ii; i++) {
			var f = fields[i];
			this.field_prototypes[f.name] = f;
		}
	};
	Type.prototype = {
		allowed_types: function() {
			var types = [];
			if (this.data.allowed_types.length > 0) {
				for (var i = 0, ii = this.data.allowed_types.length; i < ii; i++) {
					types.push(Spontaneous.Types.type(this.data.allowed_types[i]));
				}

			}
			return types;
		},
	};
	return $.extend({}, Spontaneous.Properties(), {
		init: function(callback) {
			var done = (function(callback) {
				return function(data) {
					var types = {};
					for (id in data) {
						if (data.hasOwnProperty(id)) {
							types[id] = new Type(data[id]);
						}
					}
					console.log(types)
					Spontaneous.Types.set('types', types);
					if (callback) { callback.call(type_map); };
				};
			})(callback)
			ajax.get('/types', this, done);
		},
		type: function(id) {
			return this.get('types')[id];
		}
	});
})(jQuery, Spontaneous);


