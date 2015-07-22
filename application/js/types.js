// console.log('Loading Types...');

Spontaneous.Types = (function($, S) {
	var ajax = S.Ajax
, user = S.User
, type_map = {};

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
			var allowed_types = this.data.allowed_types, types = [], a;
			if (allowed_types.length > 0) {
				for (var i = 0, ii = allowed_types.length; i < ii; i++) {
					a = allowed_types[i];
					types.push({type: Spontaneous.Types.type(a.type), as: a.as});
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
			this.title_field_name = type_data.title_field;
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
			for (i = 0, ii = boxes.length; i < ii; i++) {
				var b = boxes[i];
				this.box_ids.push(b.id);
				this.box_prototypes[b.id] = new BoxPrototype(b);
			}
		},
		isWritable: function() {
			return this.data.writable;
		},
		box_prototype: function(box_id) {
			return this.box_prototypes[box_id];
		},
		is_page: function() {
			return this.data.is_page;
		},
		is_alias: function() {
			return this.data.is_alias;
		},
		edit_url: function() {
			return S.editor_protocol + '://open?url=file://'+this.data.source;
		},
		display_title: function(content) {
			var t = this.title;
			if (user.is_developer()) {
				t += '/' + content.id();
			}
			return t;
		}
	});
	var Types = new JS.Singleton({
		include: Spontaneous.Properties,
		loaded: function(typeData) {
			var types = {};
			for (var id in typeData) {
				if (typeData.hasOwnProperty(id)) {
					types[id] = new Type(typeData[id]);
				}
			}
			Spontaneous.Types.set('types', types);
		},
		type: function(id) {
			return this.get('types')[id];
		},
		box_prototype: function(box) {
    },
		boxPrototype: function(box) {
			var names = box.type.split('.');
			var boxTypeName = names.pop();
			var contentTypeName = names.join('.');
			var contentType = this.type(contentTypeName);
			return contentType.box_prototypes[box.type_id];
		}
	});
	return Types;
}(jQuery, Spontaneous));
