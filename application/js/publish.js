// console.log('Loading Publishing...')

Spontaneous.Publishing = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var PublishingDialogue = new JS.Class(Dialogue, {
		initialize: function(content) {
			this.change_sets = [];
		},
		width: function() {
			return '90%';
		},
		title: function() {
			return "Publish Changes";
		},
		class_name: function() {
			return "publishing";
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
			var changed_wrap = dom.div("#changes.change-list"), publish_wrap = dom.div("#to-publish.change-list")
			w.append(changed_wrap, publish_wrap)
			if (change_list.length === 0) {
				var summary = dom.p('.publish-summary').text("The site is up to date");
				w.append(summary);
				this.disable_button('Publish');
			} else {
				var publish_all = dom.a('.button').text('Publish All').click(function() {
					alert('publish all');
				});
				var clear_all = dom.a('.button').text('Clear All').click(function() {
					alert('Clear all');
				});
				var changed_toolbar = dom.div('.actions').append(dom.div().text("Modified pages")).append(publish_all);
				var publish_toolbar = dom.div('.actions').append(dom.div().text("Publish pages")).append(clear_all);
				var changed_entries = dom.div('.change-sets'), publish_entries = dom.div('.change-sets')
				changed_wrap.append(changed_toolbar, changed_entries);
				publish_wrap.append(publish_toolbar, publish_entries);
				for (var i = 0, ii = change_list.length; i < ii; i++) {
					var cs = new ChangeSet(i, this, change_list[i]);
					this.change_sets.push(cs);
					changed_entries.append(cs.panel())
				}
				publish_entries.append(dom.div('.instructions').text('Add pages to publish from the list on the left'));
				this.changed_entries = changed_entries;
				this.publish_entries = publish_entries;
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
			// if (!state && this.publish_all) {
				// this.publish_all = false;
				// this.update_publish_all_view();
			// }
			var id = 'cs-' + change_set.id, panel, __this = this;
			if (state) {
				this.publish_entries.find('.instructions').hide();
				panel = change_set.selected_panel(id).hide();
				this.publish_entries.prepend(panel);
				change_set.panel().disappear();
				panel.appear();
			} else {
				panel = this.publish_entries.find('#'+id)
				panel.disappear(function() {
					panel.remove();
					var entries = __this.publish_entries;
					if (entries.find('.change-set').length == 0) {
						entries.find('.instructions').fadeIn();
					}
				});
				change_set.panel().appear();
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
		initialize: function(id, dialogue, change) {
			this.id = id;
			this.dialogue = dialogue;
			this.change = change;
			this.selected = false;
		},
		panel: function() {
			if (!this._panel) {
				var w = dom.div('.change-set'), inner = dom.div('.inner'), page_list = dom.div('.pages'), add = dom.div('.add').append(dom.span().text('+')), pages = this.pages();
				for (var i = 0, ii = pages.length; i < ii; i++) {
					page_list.append(dom.div('.title').text(pages[i].title).append(dom.div('.url').text(pages[i].path)));
				}
				add.click(function() {
					this.select_toggle();
				}.bind(this))
				inner.append(page_list, add)
				w.append(inner)
				this.wrapper = w;
				this._panel = w;
			}
			return this._panel;
		},
		selected_panel: function(id) {
			var panel = this.panel().clone().attr('id', id);
			panel.find('.add').click(this.select_toggle.bind(this)).find('span').text('-');
			return panel;
		},
		select: function(state) {
			this.selected = state;
			// this.update_view();
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

