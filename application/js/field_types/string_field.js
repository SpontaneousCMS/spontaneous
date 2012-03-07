// console.log('Loading StringField...')
Spontaneous.FieldTypes.StringField = (function($, S) {
	var dom = S.Dom;
	var StringFieldConflictView = new JS.Class({
		initialize: function(dialogue, conflict) {
			this.dialogue = dialogue;
			this.conflict = conflict;
			this.server_version = conflict.version;
			this.values = conflict.values;
			this.differ = new S.Diff();
		},
		panel: function() {
			var labels = dom.div('.string-field-conflict.labels.differences'), outer = dom.div(), diff_outer = dom.div('.string-field-conflict.changes.differences'), local_diff = dom.div('.original.diff'), computed_diff = dom.div('.final.diff');
			var local_diff_label = dom.div('.diff').text("Changes made by other person");
			var final_diff_label = dom.div('.diff').text("Their changes merged with yours");
			var server_change = this.diff(this.values.local_original, this.values.server_original);
			var local_change = this.diff(this.values.local_original, this.values.local_edited);
			var merge = this.differ.patch_apply(local_change.patches, this.values.server_original);
			var merge_change = this.diff(this.values.local_original, merge[0]);
			var local_mods = this.differ.diff_prettyHtml(server_change.diff);
			var merge_mods = this.differ.diff_prettyHtml(merge_change.diff);

			local_diff.append(local_mods).click(function() {
				this.useValue(this.values.server_original);
				local_diff.add(computed_diff).removeClass('selected');
				local_diff.addClass('selected');
			}.bind(this));

			computed_diff.append(merge_mods).click(function() {
				this.useValue(merge[0]);
				local_diff.add(computed_diff).removeClass('selected');
				computed_diff.addClass('selected');
			}.bind(this));

			labels.append(local_diff_label, final_diff_label);
			diff_outer.append(local_diff, computed_diff);
			outer.append(labels, diff_outer);
			return outer;
		},

		diff: function(original, edited) {
			var diff = this.differ.diff_main(original, edited, false);
			this.differ.diff_cleanupSemantic(diff);
			var patches = this.differ.patch_make(original, edited, diff);
			return {
				diff: diff,
				patches: patches
			};
		},
		useValue: function(value) {
			this.use_value = value;
			this.dialogue.resolve_value(this.conflict, value);
		}
	});

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
			return this.input_name('unprocessed_value');
		},
		version_name: function() {
			return this.input_name('version');
		},
		input_name: function(name) {
			return 'field['+this.schema_id()+']['+name+']';
		},
		schema_id: function() {
			return this.type.schema_id;
		},
		version: function() {
			return this.data.version;
		},
		set_version: function(version) {
			this.data.version = version;
		},
		label: function() {
			return this.title;
		},
		generate_input: function() {
			return dom.input(dom.id(this.css_id()), {'type':'text', 'name':this.form_name(), 'value':this.unprocessed_value()})
		},
		input: function() {
			if (!this._input) {
				this._input = this.generate_input();
				this._input.data('field', this);
			}
			return this._input;
		},

		edited_value: function() {
			return this.input().val();
		},
		is_modified: function() {
			// always returns true because the ui value will always be sent and would override the server
			// version in the case of a conflict
			return true;
		},
		original_value: function() {
			return this.unprocessed_value();
		},
		set_edited_value: function(value) {
			this.input().val(value);
		},
		cancel_edit: function() {
		},
		close_edit: function() {
			this._input = null;
			this._version_input = null;
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
		on_show: function() {
		},
		focus: function() {
			this.input().focus().select();
		},
		// true for fields with a text input
		accepts_focus: true,
		on_focus: function() {
			this.input().parents('.field').first().addClass('focus');
		},
		on_blur: function() {
			this.input().parents('.field').first().removeClass('focus');
		},
		conflict_view: function(dialogue, conflict) {
			return new StringFieldConflictView(dialogue, conflict);
		}
	});

	StringField.ConflictView = StringFieldConflictView;

	return StringField;
})(jQuery, Spontaneous);

