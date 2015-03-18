// console.log('Loading Publishing...')

Spontaneous.Publishing = (function($, S) {
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue, User = S.User;

	var PublishingDialogue = new JS.Class(Dialogue, {
		initialize: function(content) {
			this.change_sets = [];
			var callback = this.page_lock_removed.bind(this);
			var page_lock_removed = function(event) {
				callback($.parseJSON(event.data));
			};
			S.EventSource.addEventListener('page_lock_status', page_lock_removed);
			this.page_lock_removed_listener = page_lock_removed;
		},
		page_lock_removed: function(page_ids) {
			var changes = this.change_sets, toUnlock = [];
			page_ids.forEach(function(id) {
				toUnlock = toUnlock.concat(changes.filter(function(c) { return c.change.id == id; }));
			});

			toUnlock.forEach(function(cs) {
				cs.unlock();
			});
		},
		cleanup: function() {
			S.EventSource.removeEventListener('page_lock_status', this.page_lock_removed_listener);
		},
		width: function() {
			return '90%';
		},
		title: function() {
			return 'Publish Changes';
		},
		class_name: function() {
			return 'publishing';
		},
		body: function() {
			var wrapper = dom.div('#publishing-dialogue');
			var spinner = dom.div('.spinner');
			wrapper.append(spinner);

			this.spinnerWrap = spinner;
			this.wrapper = wrapper;
			this.spinner = S.Progress(spinner[0], 48, {period: 800, segment_length: 0.30});
			this.spinner.start();
			spinner.append(dom.div().append(dom.p().text('Loading changes...')));
			Spontaneous.Ajax.get('/changes', this.change_list_loaded.bind(this));
			return wrapper;
		},
		buttons: function() {
			btns = {};
			if (User.is_developer()) {
				btns['Rerender'] = this.rerender.bind(this);
			}
			btns['Publish'] = this.publish.bind(this);
			return btns;
		},
		publish: function() {
			var ids = [], changes = this.changes_to_publish();
			for (var i = 0, ii = changes.length; i < ii; i++) {
				ids = ids.concat(changes[i].page_ids());
			}
			if (ids.length > 0) {
				Spontaneous.Ajax.post('/changes', {'page_ids': ids}, this.publish_requested.bind(this));
			} else {
			}
		},

		rerender: function() {
			Spontaneous.Ajax.post('/changes/rerender', {}, this.publish_requested.bind(this));
		},

		publish_requested: function() {
			Spontaneous.TopBar.publishing_started();
			this.close();
		},

		change_list_loaded: function(outstanding) {
			var change_list = outstanding.changes
			, w = this.wrapper
			, self = this
			, changed_wrap = dom.div('#changes.change-list').css('opacity', 0)
			, publish_wrap = dom.div('#to-publish.change-list').css('opacity', 0)
			, must_publish_all = outstanding.first_publish || outstanding.must_publish_all
			, spinner = this.spinner
			, spinnerWrap = this.spinnerWrap
			, append_to
			, stop_spinner = function() {
				spinner.stop();
				spinnerWrap.remove();
			};
			if (must_publish_all) {
				w.addClass('first-publish');
			}
			if (change_list.length === 0) {
				var summary = dom.p('.publish-up-to-date').text('The site is up to date');
				w.append(summary);
				self.disable_button('Publish');
				stop_spinner();
			} else {
				var publish_all = dom.a('.button').text('Publish All').click(function() {
					self.set_publish_all(true);
				}.bind(self));
				var clear_all = dom.a('.button').text('Clear All').click(function() {
					self.set_publish_all(false);
				}.bind(self));

				var changed_toolbar = dom.div('.actions').append(dom.div().text('Modified pages')).append(publish_all);
				var publish_toolbar = dom.div('.actions').append(dom.div().text('Publish pages'));
				if (!must_publish_all) {
					publish_toolbar.append(clear_all);
				}
				var changed_entries = dom.div('.change-sets'), publish_entries = dom.div('.change-sets');
				changed_wrap.append(changed_toolbar, changed_entries);
				publish_wrap.append(publish_toolbar, publish_entries);
				append_to = changed_entries;
				if (must_publish_all) {
					append_to = publish_entries;
				}
				for (var i = 0, ii = change_list.length; i < ii; i++) {
					var cs = new ChangeSet(i, self, change_list[i], must_publish_all);
					self.change_sets.push(cs);
					append_to.append(cs.panel());
				}
				if (!must_publish_all) {
					publish_entries.append(dom.div('.instructions').text('Add pages to publish from the list on the left'));
				}
				stop_spinner();
				w.empty();
				w.append(changed_wrap, publish_wrap);
				changed_wrap.add(publish_wrap).velocity({opacity: 1});
				self.changed_entries = changed_entries;
				self.publish_entries = publish_entries;
				this.spinner = this.spinnerWrap = null;
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
				panel = this.publish_entries.find('#'+id);
				panel.disappear(function() {
					panel.remove();
					var entries = __this.publish_entries;
					if (entries.find('.change-set').length === 0) {
						entries.find('.instructions').fadeIn();
					}
				});
				change_set.panel().appear();
			}
		},
		change_set_dependency_state: function(dependentPage) {
			var self = this;
			var dependentSet = this.change_sets.filter(function(set) {
				return set.change.id === dependentPage.id;
			});
			var dependentGraph = this.change_sets.filter(function(set) {
				return set.has_dependency(dependentPage);
			});
			var group = dependentSet.concat(dependentGraph);
			group.forEach(function(set) {
				set.select(true);
			});
		},
		dependency_forces_publish: function(set) {
			var dependencyPage = set.page();
			return this.change_sets.some(function(set) {
				return set.selected && set.dependent_pages().some(function(page) {
					return page.id === dependencyPage.id;
				});
			});
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
			return this.selected();
		}
	});

	var Page = new JS.Class({
		initialize: function(details) {
			$.extend(this, details);
		},
		isUnpublished: function() {
			return !this.published_at;
		},
		isDependent: function() {
			return !this.hasOwnProperty('dependent');
		},

		panel: function() {
			var self = this
			, pageTitle = dom.span('.page-title').html(this.title)
			, classes = '.title' + (this.isDependent() ? '.dependent' : '')
			, modificationDate = dom.div('.modification-date').html(this.modifiedAt())
			, publicationDate = dom.div('.publication-date').html(this.publishedAt())
			, metadata = dom.div('.dates').append(modificationDate, publicationDate);
			if (this.isUnpublished()) {
				pageTitle.attr('title', 'This page is new and has never been published');
			}
			return dom.div(classes).append(pageTitle, dom.div('.url').text(this.url)).append(metadata).click(function() {
				S.Dialogue.close();
				S.Location.load_id(self.id);
			});
		},
		modifiedAt: function() {
			return 'Modified: ' + this.formatDate(this.modified_at);
		},
		publishedAt: function() {
			var date;
			if (this.isUnpublished()) {
				date = 'Never';
			} else {
				date = this.formatDate(this.published_at);
			}
			return 'Published: ' + date;
		},
		formatDate: function(dateString) {
			if (!dateString) { return ''; }
			var d = new Date(dateString);
			// use date.js formatting
			return d.toString('d MMM yyyy, HH:mm');
		}
	});
	var ChangeSet = new JS.Class({
		initialize: function(id, dialogue, change, selected) {
			this.id = id;
			this.dialogue = dialogue;
			this.change = change;
			this.selected = selected || false;
			this.mustPublish = selected || false;
		},
		locks: function(){
			return this.change.update_locks;
		},
		isLocked: function() {
			return this.locks().length > 0;
		},
		unlock: function() {
			var w = this.wrapper;
			w.removeClass('locked').find('.lock-state').remove();
			this.locks().length = 0;
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
			, add = dom.div('.add').append(dom.span().text(''))
			, page = this.page()
			, pages = this.dependent_pages()
			, locked = this.isLocked()
			, info = dom.div('.info').hide();

			if (page.isUnpublished()) {
				w.addClass('unpublished');
			}
			if (locked) {
				w.addClass('locked');
				var lockState = dom.div('.lock-state')
				, title = dom.h3().html('<strong>Cannot publish page</strong> until the following actions have completed:')
				, details = dom.div('.locks')
				, locks = this.locks();
				locks.forEach(function(lock) {
					var line = dom.p();
					line.text(lock.description);
					line.prepend(dom.strong().text(lock.location));
					details.append(line);
				});
				lockState.append(title, details);
				info.append(lockState);
				page_list.append(info);
				add.hover(function() {
					info.show().velocity({'width': '100%'}, 150);
				}, function() {
					info.hide().css('width', 0);
				});
			}
			page_list.append(page.panel());
			for (var i = 0, ii = pages.length; i < ii; i++) {
				page_list.append(pages[i].panel());
			}

			add.click(function() {
				this.select_toggle();
			}.bind(this));

			inner.append(page_list);

			if (!this.mustPublish) {
				inner.append(add);
			}
			w.append(inner);
			return w;
		},
		selected_panel: function(id) {
			var panel = this.createPanel().attr('id', id);
			panel.find('.add').find('span').addClass('active');
			return panel;
		},
		select: function(state) {
			var self = this;
			if (this.isLocked()) { return; }
			if (state === self.selected) { return; }
			if (!state && self.dependency_forces_publish()) {
				return;
			}
			self.selected = state;
			self.dialogue.change_set_state(self, self.selected);
			if (state) {
				self.dependent_pages().forEach(function(page) {
					self.dialogue.change_set_dependency_state(page);
				});
				var page = self.page();
				if (page.isUnpublished()) {
					self.dialogue.change_set_dependency_state(page);
				}
			}
		},
		select_toggle: function() {
			this.select(!this.selected);
		},
		update_view: function() {
			if (this.selected) {
				this.wrapper.addClass('selected');
			} else {
				this.wrapper.removeClass('selected');
			}
		},
		page: function() {
			return new Page(this.change);
		}.cache('_page_'),

		dependency_forces_publish: function() {
			return this.dialogue.dependency_forces_publish(this);
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
		},
		has_dependency: function(onPage) {
			var dependents = this.dependent_pages();
			if (dependents.length === 0) { return false; }
			var matches = dependents.filter(function(dep) {
				return dep.id === onPage.id;
			});
			return matches.length > 0;
		}
	});

	var Publishing = new JS.Singleton({
		open_dialogue: function() {
			Dialogue.open(new PublishingDialogue());
		}
	});

	return Publishing;
})(jQuery, Spontaneous);

