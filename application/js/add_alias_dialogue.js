
Spontaneous.AddAliasDialogue = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var AddAliasDialogue = new JS.Class(Dialogue, {
		initialize: function(box, type) {
			console.log(type);
			this.box = box;
			this.type = type;
		},
		title: function() {
			console.log('title', this.box.name(), this.type)
			return 'Add alias to &ldquo;' + this.box.name() + '&rdquo;';
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
				S.Ajax.post(["/alias", this.box.container.id(), this.box.schema_id()].join("/"), {'alias_id':this.type.schema_id, 'target_id':this.target.id}, this, this.alias_added);
			}
		},
		alias_added: function(data) {
			this.close();
			this.box.update_pieces(data);
		},
		select_target: function(target) {
			this.target = target;
		},
		body: function() {
			var editing = dom.div('#add-alias-dialogue'), outer = dom.div(), instructions = dom.p('.instructions'),
				targets = this.targets, __dialogue = this;
			instructions.html("Choose a target:")
			editing.append(instructions, outer)
			Spontaneous.Ajax.get(['/targets', this.type.schema_id].join('/'), this, this.targets_loaded);
			this._outer = outer;
			return editing;
		},
		targets_loaded: function(targets) {
			console.log('targets loaded', targets)
			var outer = this._outer, __dialogue = this;
			this.targets = targets;
			$.each(targets, function(i, target) {
				console.log('target', target)
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

