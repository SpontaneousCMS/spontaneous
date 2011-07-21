
Spontaneous.AddHomeDialogue = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var AddHomeDialogue = new JS.Class(Dialogue, {
		initialize: function(types) {
			this.types = types;
		},
		title: function() {
			return "Create site home page";
		},
		width: function() {
			return '50%';
		},
		buttons: function() {
			var btns = {};
			btns["Create"] = this.create_home.bind(this);
			return btns;
		},

		uid: function() {
			return this.content.uid() + '!editing';
		},
		create_home: function() {
			if (this.type) {
				S.Ajax.post('/root', {'type':this.type.schema_id}, this, this.home_created);
			}
		},
		home_created: function(data) {
			window.location.href = S.Ajax.namespace
		},
		select_type: function(type) {
			this.type = type;
		},
		body: function() {
			var editing = dom.div('#create-home-dialogue'), outer = dom.div(), instructions = dom.p('.instructions'),
				types = this.types, __dialogue = this;
			instructions.html("You don't have a home page. Please choose a type below and hit <span class=\"button\">Create</span> to add one")
			$.each(types, function(i, type) {
				if (type.is_page()) {
					var d = dom.div('.type').text(type.title).click(function() {
						$('.type', outer).removeClass('selected');
						__dialogue.select_type(type);
						$(this).addClass('selected');;
					});
					outer.append(d)
				}
			});
			editing.append(instructions, outer)
			return editing;
		},
		cancel_button: function() {
			return false;
		},
	});
	return AddHomeDialogue;
})(jQuery, Spontaneous);


