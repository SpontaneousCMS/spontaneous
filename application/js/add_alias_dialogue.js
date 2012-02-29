
Spontaneous.AddAliasDialogue = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var AddAliasDialogue = new JS.Class(Dialogue, {
		initialize: function(box_view, type, position) {
			this.box_view = box_view;
			this.box_view.bind('entry_added', this.alias_added.bind(this))
			this.type = type;
			this.insert_position = position;
		},
		title: function() {
			return 'Add alias to &ldquo;' + this.box_view.name() + '&rdquo;';
		},
		buttons: function() {
			var btns = {};
			btns["Add"] = this.add_alias.bind(this);
			return btns;
		},

		uid: function() {
			return this.content.uid() + '!add-alias';
		},
		add_alias: function() {
			if (this.target) {
				this.box_view.add_alias(this.target.id, this.type, this.insert_position);
			}
		},
		alias_added: function() {
			this.close();
		},
		select_target: function(target) {
			this.target = target;
		},
		box_owner: function() {
			return this.box_view.box.container;
		},
		box: function() {
			return this.box_view.box;
		},
		body: function() {
			var editing = dom.div('#add-alias-dialogue')
				, outer = dom.div('.typelist')
				, instructions = dom.p('.instructions')
				, __dialogue = this;
			instructions.html("Choose a target:");
			editing.append(instructions, outer);
			Spontaneous.Ajax.get(['/targets', this.type.schema_id, this.box().id()].join('/'), this.targets_loaded.bind(this));
			this._outer = outer;
			return editing;
		},

		targets_loaded: function(targets) {
			var outer = this._outer, __dialogue = this;
			this.targets = this.sort_targets(targets);
			$.each(targets, function(i, target) {
				var d = dom.div('.type').html(target.title).click(function() {
					$('.type', outer).removeClass('selected');
					__dialogue.select_target(target);
					$(this).addClass('selected');;
				});
				outer.append(d)
			});

		},
		sort_targets: function(targets) {
			var comparator = function(a, b) {
				var at = a.title, bt = b.title;
				if (at > bt) { return 1; }
				if (at < bt) { return -1; }
				return 0;
			}
			return targets.sort(comparator);
		}
	});
	return AddAliasDialogue;
})(jQuery, Spontaneous);

