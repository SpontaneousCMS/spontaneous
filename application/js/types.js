// console.log('Loading Types...');

Spontaneous.Types = (function($, S) {
	var ajax = S.Ajax, type_map = {};
	var BoxPrototype = new JS.Class({
		initialize: function(type_data) {
			this.data = type_data;
			this.title = type_data.title;
			var fields = this.data.fields;
			this.field_prototypes = {};
			this.field_names = [];
			for (var i = 0, ii = fields.length; i < ii; i++) {
				var f = fields[i];
				this.field_names.push(f.name);
				this.field_prototypes[f.name] = f;
			}
		},
		allowed_types: function() {
			var types = [];
			if (this.data.allowed_types.length > 0) {
				for (var i = 0, ii = this.data.allowed_types.length; i < ii; i++) {
					types.push(Spontaneous.Types.type(this.data.allowed_types[i]));
				}
			}
			return types;
		}
	});
	var Type = new JS.Class({
		initialize: function(type_data) {
			this.data = type_data;
			this.schema_id = type_data.id;
			this.type = type_data.type;
			this.title = type_data.title;
			this.field_prototypes = {};
			this.field_names = [];
			this.box_prototypes = {};
			this.box_ids = [];
			var fields = this.data.fields, boxes = this.data.boxes;
			for (var i = 0, ii = fields.length; i < ii; i++) {
				var f = fields[i];
				this.field_names.push(f.name);
				this.field_prototypes[f.name] = f;
			}
			for (var i = 0, ii = boxes.length; i < ii; i++) {
				var b = boxes[i];
				this.box_ids.push(b.id);
				this.box_prototypes[b.id] = new BoxPrototype(b);
			}
		},
		box_prototype: function(box_id) {
			return this.box_prototypes[box_id];
		},
		allowed_types: function() {
			var types = [];
			if (this.data.allowed_types.length > 0) {
				for (var i = 0, ii = this.data.allowed_types.length; i < ii; i++) {
					types.push(Spontaneous.Types.type(this.data.allowed_types[i]));
				}
			}
			return types;
		},
		is_page: function() {
			return this.data.is_page;
		},
		is_alias: function() {
			return this.data.is_alias;
		}
	});
	var Types = new JS.Singleton({
		include: Spontaneous.Properties,
		init: function(callback) {
			var done = (function(callback) {
				return function(data) {
					var types = {};
					for (id in data) {
						if (data.hasOwnProperty(id)) {
							types[id] = new Type(data[id]);
						}
					}
					Spontaneous.Types.set('types', types);
					if (callback) { callback.call(type_map); };
				};
			})(callback)
			ajax.get('/types', this, done);
		},
		type: function(id) {
			return this.get('types')[id];
		},
		box_prototype: function() {

		}
	});
	return Types;
})(jQuery, Spontaneous);

