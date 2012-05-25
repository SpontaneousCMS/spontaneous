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
			var wrapper = dom.div('#publishing-dialogue');
			this.wrapper = wrapper;
			Spontaneous.Ajax.get(['/publish', 'changes'].join('/'), this.change_list_loaded.bind(this));
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
				ids = ids.concat(changes[i].page_ids());
			}
			if (ids.length > 0) {
				Spontaneous.Ajax.post(['/publish', 'publish'].join('/'),{'page_ids': ids}, this.publish_requested.bind(this));
			} else {
			}
		},


		publish_requested: function() {
			Spontaneous.TopBar.publishing_started();
			this.close();
		},

		change_list_loaded: function(change_list) {
			var w = this.wrapper, __dialogue = this;
			w.empty();
			var changed_wrap = dom.div("#changes.change-list"), publish_wrap = dom.div("#to-publish.change-list")
			w.append(changed_wrap, publish_wrap)
			if (change_list.length === 0) {
				var summary = dom.p('.publish-up-to-date').text("The site is up to date");
				w.append(summary);
				this.disable_button('Publish');
			} else {
				var publish_all = dom.a('.button').text('Publish All').click(function() {
					this.set_publish_all(true);
				}.bind(this));
				var clear_all = dom.a('.button').text('Clear All').click(function() {
					this.set_publish_all(false);
				}.bind(this));
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
			$.each(this.change_sets, function() {
				this.select(state);
			});
		},
		change_set_state: function(change_set, state) {
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
			// var changes = [], selected = this.selected(), cs;
			// for (var i = 0, ii = selected.length; i < ii; i++) {
			// 	cs = selected[i];
			// 	changes.push(cs)
			// }
			// return changes;
			return this.selected();
		}
	});

	var Page = new JS.Class({
		initialize: function(details) {
			$.extend(this, details);
		},
		isDependent: function() {
			return !this.hasOwnProperty("dependent");
		},
		panel: function() {
			var self = this
			, classes = ".title" + (this.isDependent() ? ".dependent" : "");
			return dom.div(classes).text(this.title).append(dom.div('.url').text(this.url)).append(dom.div('.modification-date').text(this.modifiedAt())).click(function() {
				S.Dialogue.close();
				S.Location.load_id(self.id);
			});
		},
		modifiedAt: function() {
			return "Modified: " + this.modified_at;
		}
	});
	var ChangeSet = new JS.Class({
		initialize: function(id, dialogue, change) {
			this.id = id;
			this.dialogue = dialogue;
			this.change = change;
			this.selected = false;
		},
		page_ids: function() {
			var ids = [this.change.id];
			return ids.concat(this.dependent_pages().map(function(p) { return p.id; }));
		},
		panel: function() {
			if (!this._panel) {
				this._panel = this.createPanel();
				this.wrapper = this._panel;
			}
			return this._panel;
		},
		createPanel: function() {
			var w = dom.div('.change-set')
			, inner = dom.div('.inner')
			, page_list = dom.div('.pages')
			, add = dom.div('.add').append(dom.span().text('+'))
			, page = this.page()
			, pages = this.dependent_pages();

			page_list.append(page.panel());
			for (var i = 0, ii = pages.length; i < ii; i++) {
				page_list.append(pages[i].panel());
			}
			add.click(function() {
				this.select_toggle();
			}.bind(this));
			inner.append(page_list, add);
			w.append(inner);
			return w;
		},
		selected_panel: function(id) {
			var panel = this.createPanel().attr('id', id);
			panel.find('.add').find('span').text('-');
			return panel;
		},
		select: function(state) {
			if (state === this.selected) { return; }
			this.selected = state;
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
		page: function() {
			return new Page(this.change);
		},
		dependent_pages: function() {
			if (!this._dependent_pages) {
				this._dependent_pages = this.change.dependent.map(function(p) {
					return new Page(p);
				}).sort(function(p1, p2) {
					var a = p2.depth, b = p1.depth;
					if (a == b) return 0;
					return (a < b ? -1 : 1);
				});
			}
			return this._dependent_pages;
		}
	});

	var Publishing = new JS.Singleton({
		open_dialogue: function() {
			Dialogue.open(new PublishingDialogue());
		}
	});

	return Publishing;
})(jQuery, Spontaneous);

