// console.log('Loading Publishing...')

Spontaneous.Publishing = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var PublishingDialogue = new JS.Class(Dialogue, {
		initialize: function(content) {
			this.change_sets = [];
		},
		body: function() {
			var wrapper = dom.div('#publishing-dialogue').text('publishing')
			this.wrapper = wrapper;
			Spontaneous.Ajax.get(['/publish', 'changes'].join('/'), this, this.change_list_loaded);
			return wrapper;
		},
		buttons: function() {
			btns = {};
			btns['Publish'] = this.publish.bind(this);
			return btns;
		},
		publish: function() {
			var ids = [], changes = this.changes_to_publish();
			for (var i = 0, ii = changes.length; i < ii; i++) {
				ids.push(changes[i].id);
			}
			if (ids.length > 0) {
				Spontaneous.Ajax.post(['/publish', 'publish'].join('/'),{'change_set_ids': ids}, this, this.publish_requested);
			} else {
			}
		},


		publish_requested: function() {
			console.log('publish requested')
			Spontaneous.TopBar.publishing_started();
			this.close();
		},
		change_list_loaded: function(change_list) {
			var w = this.wrapper, __dialogue = this;
			w.empty();
			if (change_list.length === 0) {
				var summary = dom.p('.publish-summary').text("The site is up to date");
				w.append(summary);
				this.disable_button('Publish');
			} else {
				var summary = dom.p('.publish-summary').text(change_list.length + " changes");
				var cb = dom.input('.checkbox').change(function() {
					var checked = $(this).is(':checked');
					__dialogue.set_publish_all(checked);
				});
				var label = dom.label('.publish-all').append(cb).append('Publish All');
				summary.append(label)
				w.append(summary);
				this.publish_all_label = label;
				for (var i = 0, ii = change_list.length; i < ii; i++) {
					var cs = new ChangeSet(this, change_list[i]);
					this.change_sets.push(cs);
					w.append(cs.panel())
				}
			}
		},
		set_publish_all: function(state) {
			this.publish_all = state;
			this.update_publish_all_view();
			if (this.publish_all) {
				$.each(this.change_sets, function() {
					this.select(true);
				});
			} else {
				$.each(this.change_sets, function() {
					this.select(false);
				});
			}
		},
		update_publish_all_view: function() {
			if (this.publish_all) {
				this.publish_all_label.addClass('checked')
				$('input[type="checkbox"]', this.publish_all_label).attr('checked', true);
			} else {
				this.publish_all_label.removeClass('checked')
				$('input[type="checkbox"]', this.publish_all_label).attr('checked', false);
			}
		},
		change_set_state: function(change_set, state) {
			if (!state && this.publish_all) {
				this.publish_all = false;
				this.update_publish_all_view();
			}
		},
		selected: function() {
			var selected = [], cs;
			for (var i = 0, ii = this.change_sets.length; i < ii; i++) {
				cs = this.change_sets[i];
				if (cs.selected) {
					selected.push(cs);
				}
			}
			return selected;
		},
		changes_to_publish: function() {
			var changes = [], selected = this.selected(), cs;
			for (var i = 0, ii = selected.length; i < ii; i++) {
				cs = selected[i];
				changes = changes.concat(cs.change.changes)
			}
			return changes;
		}
	});

	var ChangeSet = new JS.Class({
		initialize: function(dialogue, change) {
			this.dialogue = dialogue;
			this.change = change;
			this.selected = false;
		},
		panel: function() {
			var w = dom.div('.change-set'), pages = this.pages(), titles = dom.div('.titles');
			for (var i = 0, ii = pages.length; i < ii; i++) {
				titles.append(dom.a().text(pages[i].title).append(dom.span().text(pages[i].path)));
			}
			w.click(function() {
				this.select_toggle();
			}.bind(this))
			w.append(titles);
			this.wrapper = w;
			return w;
		},
		select: function(state) {
			this.selected = state;
			this.update_view();
			this.dialogue.change_set_state(this, this.selected);
		},
		select_toggle: function() {
			this.select(!this.selected)
		},
		update_view: function() {
			if (this.selected) {
				this.wrapper.addClass('selected')
			} else {
				this.wrapper.removeClass('selected')
			}
		},
		pages: function() {
			if (!this._pages) {
				this._pages = this.change.pages.sort(function(p1, p2) {
					var a = p1.depth, b = p2.depth;
					if (a == b) return 0;
					return (a < b ? -1 : 1);
				});
			}
			return this._pages;
		}
	});

	var Publishing = new JS.Singleton({
		open_dialogue: function() {
			Dialogue.open(new PublishingDialogue());
		}
	});

	return Publishing;
})(jQuery, Spontaneous);

