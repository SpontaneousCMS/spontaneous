// console.log('Loading StringField...')
Spontaneous.FieldTypes.StringField = (function($, S) {
	var dom = S.Dom;
	var StringField = new JS.Class({
		include: Spontaneous.Properties,

		initialize: function(owner, data) {
			this.content = owner;
			this.name = data.name;
			var content_type = owner.type();
			this.type = content_type.field_prototypes[this.name];
			this.title = this.type.title;
			this.update(data);
		},
		uid: function() {
			return this.content.uid() + '['+this.name+']';
		},
		set_value: function(new_value) {
		},

		unload: function() {
		},
		update: function(values) {
			this.data = values;
			this.set('value', values.processed_value);
			this.set('unprocessed_value', values.unprocessed_value);
		},
		preview: function() {
			return this.get('value')
		},
		activate: function(el) {
			el.find('a[href^="/"]').click(function() {
				S.Location.load_path($(this).attr('href'));
				return false;
			});
		},
		value: function() {
			return this.get('value');
		},
		unprocessed_value: function() {
			return this.data.unprocessed_value;
		},
		is_image: function() {
			return false;
		},
		is_file: function() {
			return false;
		},

		id: function() {
			return this.content.id();
		},
		css_id: function() {
			return 'field-'+this.name+'-'+this.id();
		},
		form_name: function() {
			return 'field['+this.name+'][unprocessed_value]';
		},
		label: function() {
			return this.title;
		},
		input: function() {
			if (!this._input) {
				this._input = dom.input(dom.id(this.css_id()), {'type':'text', 'name':this.form_name(), 'value':this.unprocessed_value()})
			}
			return this._input;
		},
		close_edit: function() {
			this._input = null;
		},
		edit: function() {
			return this.input();
		},
		toolbar: function() {
			return false;
		},
		footer: function() {
			return false;
		},
		on_focus: function() {
			this.input().parents('.field').first().addClass('focus');
		},
		on_blur: function() {
			this.input().parents('.field').first().removeClass('focus');
		}
	});

	return StringField;
})(jQuery, Spontaneous);

