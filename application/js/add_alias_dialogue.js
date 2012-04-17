
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
			var self = this
			, editing = dom.div('#add-alias-dialogue')
				, outer = dom.div('.typelist')
				, paging = dom.div(".paging")
				, search = dom.div(".search")
				, progress = dom.div(".progress")
				, instructions = dom.p('.instructions')
				, __dialogue = this
				, timeout = null
				, searchDelay = 200
				, clearTimeout = function() {
					if (timeout) { window.clearTimeout(timeout); timeout = null; }
				}
				, load_targets = function(query) {
					clearTimeout();
					var params = {};
					if (query !== "") {
						params["query"] = query;
					}

					self.spinner.start();
					Spontaneous.Ajax.get(['/targets', self.type.schema_id, self.box().id()].join('/'), params, self.targets_loaded.bind(self));
				}
				, input = dom.input({"type":"search", "placeholder":"Search..."}).keydown(function(event) {
					if (event.keyCode === 13) {
						load_targets(input.val());
					}
					if (event.keyCode === 27) {
						if (input.val() === "") {
							return true;
						}
						input.val("");
						load_targets();
						return false;
					}
				}).keyup(function() {
					clearTimeout();
					var val = input.val();
					if (val === "" || val.length > 1) {
						timeout = window.setTimeout(function() {
							load_targets(val);
						}, searchDelay);
					}
				})
			instructions.html("Choose a target:");

			search.append(input)
			paging.append(progress, search)
			this.spinner = S.Progress(progress[0], 16);
			editing.append(paging, outer);
			load_targets();
			this.paging = paging;
			this._outer = outer;
			return editing;
		},

		targets_loaded: function(results) {
			var outer = this._outer, wrap, self = __dialogue = this, targets = results.targets;
			window.setTimeout(function() { self.spinner.stop() }, 300);
			this.targets = this.sort_targets(targets);
			outer.empty();
			wrap = dom.div();
			$.each(targets, function(i, target) {
				var d = dom.div('.type').html(target.title).click(function() {
					$('.type', outer).removeClass('selected');
					__dialogue.select_target(target);
					$(this).addClass('selected');;
				});
				wrap.append(d)
			});
			outer.append(wrap)
			this._contents = wrap;
			this.manager.updateLayout();
		},
		contentsHeight: function() {
			return this.paging.outerHeight() + this._contents.outerHeight();
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

