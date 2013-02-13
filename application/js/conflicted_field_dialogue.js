
Spontaneous.ConflictedFieldDialogue = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var ConflictedFieldDialogue = new JS.Class(Dialogue, {
		initialize: function(parent_view, conflicted_fields) {
			this.parent_view = parent_view;
			this.conflicted_fields = conflicted_fields;
			this.active_conflict = 0;
			this.wrap = dom.div('#conflicted-fields-dialogue');
		},
		title: function() {
			return "Conflicted Fields";
		},
		width: function() {
			return '90%';
		},
		buttons: function() {
			var btns = {};
			btns["Use"] = this.conflict_resolved.bind(this);
			return btns;
		},

		resolve_value: function(conflict, value) {
			conflict.value = value;
		},
		conflict_resolved: function() {
			var conflict = this.current_conflict();
			// conflict.value = this.conflict_view.use_value;
			// this.parent_view.conflict_resolved(conflict, this.conflict_view.use_value)
			if (conflict && conflict.value) {
				this.show_next_conflict();
			}
		},
		uid: function() {
			return this.content.uid() + '!editing';
		},
		create_home: function() {
			if (this.type) {
				S.Ajax.post('/site/home', {'type':this.type.schema_id}, this.home_created.bind(this));
			}
		},
		home_created: function(data) {
			window.location.href = S.Ajax.namespace
		},
		select_type: function(type) {
			this.type = type;
		},
		current_conflict: function() {
			return this.conflicted_fields[this.active_conflict];
		},

		next_conflict: function() {
			this.active_conflict += 1;
			return this.current_conflict();
		},
		conflict_panel: function(outer) {
			outer.empty();
			var conflict = this.current_conflict(),
			field = conflict.field,
			instructions = dom.p('.instructions');
			instructions.html("The field '"+field.label()+"' has been modified by another person. Please select which version you want to use.")
			var view = field.conflict_view(this, conflict);
			outer.append(instructions);
			outer.append(view.panel());
			this.conflict_view = view;
			return outer;
		},

		body: function() {
			panel = this.conflict_panel(this.wrap);
			return this.wrap;
		},
		show_next_conflict: function() {
			var conflict = this.next_conflict();
			if (conflict) {
				this.conflict_panel(this.wrap);
			} else {
				console.log('closing conflict view', this.conflicted_fields);
				this.parent_view.conflicts_resolved(this.conflicted_fields);
				this.close();
			}
		},
		cancel_button: function() {
			return false;
		},
	});
	return ConflictedFieldDialogue;
})(jQuery, Spontaneous);



