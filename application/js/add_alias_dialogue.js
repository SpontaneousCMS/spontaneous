
Spontaneous.AddAliasDialogue = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var AddAliasDialogue = new JS.Class(Dialogue, {
		initialize: function(box_view, type) {
			this.box_view = box_view;
			this.box_view.bind('entry_added', this.alias_added.bind(this))
			this.type = type;
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
				this.box_view.add_alias(this.target.id, this.type)
			}
		},
		alias_added: function() {
			this.close();
		},
		select_target: function(target) {
			this.target = target;
		},
		body: function() {
			var editing = dom.div('#add-alias-dialogue'), outer = dom.div(), instructions = dom.p('.instructions'),
				targets = this.targets, __dialogue = this;
			instructions.html("Choose a target:")
			editing.append(instructions, outer)
			Spontaneous.Ajax.get(['/targets', this.type.schema_id].join('/'), this.targets_loaded.bind(this));
			this._outer = outer;
			return editing;
		},
		targets_loaded: function(targets) {
			var outer = this._outer, __dialogue = this;
			this.targets = targets;
			$.each(targets, function(i, target) {
				var d = dom.div('.type').text(target.title).click(function() {
					$('.type', outer).removeClass('selected');
					__dialogue.select_target(target);
					$(this).addClass('selected');;
				});
				outer.append(d)
			});

		}
	});
	return AddAliasDialogue;
})(jQuery, Spontaneous);

