// console.log('Loading BoxView...')

Spontaneous.Views.BoxView = (function($, S) {
	'use strict';
	var dom = S.Dom;

	var BoxView = new JS.Class(Spontaneous.Views.View, {
		include: Spontaneous.Properties,

		initialize: function(box, dom_container) {
			this.callSuper(box);
			this.box = box;
			this.dom_container = dom_container;
			this.box.bind('entry_added', this.insert_entry.bind(this));
			this.box.bind('entry_removed', this.remove_entry.bind(this));
			this._isAttached = false;
		},

		name: function() {
			return this.box.name();
		},
		schema_id: function() {
			return this.box.schema_id();
		},

		activate: function() {
			$('> .slot-content', this.dom_container).hide();
			this.panel().show();
		},


		mouseover: function() {
			if (this.fields_preview) {
				this.fields_preview.addClass('hover');
			}
		},
		mouseout: function() {
			if (this.fields_preview) {
				this.fields_preview.removeClass('hover');
			}
		},

		panel: function() {
			if (!this._panel) {
				// var panel = $(dom.div, {'class': 'slot-content'});
				var panel = dom.div('.slot-content');
				panel.addClass('empty');
				if (this.box.has_fields()) {
					var w = dom.div('.box-fields');
					var fields = new Spontaneous.FieldPreview(this, '');
					this._subviews.push(fields);
					var fields_preview = fields.panel();
					fields_preview.prepend(dom.div('.overlay'));
					var preview_area = this.create_edit_wrapper(fields_preview);

					w.append(preview_area);
					panel.append(w);
					this.fields_preview = fields_preview;
				}

				panel.append(this.add_allowed_types_bar('top', 0));
				var entries = dom.div('.slot-entries');
				panel.append(entries);
				this.dom_container.append(panel);
				var instructions = dom.div('.slot-instructions').text('Add items using the buttons above');
				entries.append(instructions);
				if (this._isAttached) {
					this.appendEntries(entries);
				}
				entries.sortable({
					items:'> .'+this.entry_class(),
					// handle: '.title-bar',
					axis:'y',
					distance: 5,
					tolerance: 'pointer',
					helper: 'clone',
					// tolerance: 'intersect',
					scrollSpeed: 40,
					containment: 'parent',
					cursor: 'move',
					stop: function(event, ui) {
						this.re_sort(ui.item);
					}.bind(this)
				});
				panel.hide();
				this._panel = panel;
				this._entry_container = entries;
				// this._bottom_add_bar = _bottom_add_bar;
			}
			this.check_if_empty();
			return this._panel;
		},
		// relies on this view being attached to the dom
		// fills the box until all the entries have been added or the last entry
		// is at the bottom of the screen, whichever comes first.
		appendEntries: function(entries) {
			var entry_total = this.entries().length, attached = 0;
			var availableHeight = S.ContentArea.height() - entries.position().top;
			for (var i = 0, ee = this.entries(), ii = entry_total;i < ii; i++) {
				var entry = ee[i];
				entries.append(this.claim_entry(entry));
				attached++;
				var contentHeight = entries.height(), gap = availableHeight - contentHeight;
				if (gap < 0) { // wait until there's an overlap so we see a scrollbar
					break;
				}
			}
			if (attached < entry_total) {
				var scrollLoad = function(view, loadedCount, entries, container) {
					var position = loadedCount, increment = 3, total = entries.length;
					return function() {
						if (position >= total) { return; }
						var availableHeight = S.ContentArea.height() - container.position().top;
						var added = 0;
						for (var i = position, ii = total; i < ii; i++) {
							container.append(view.claim_entry(entries[i]));
							added++;
							var contentHeight = container.height(), gap = availableHeight - contentHeight;
							if (gap < 0) { // wait until there's an overlap so we see a scrollbar
								break;
							}
						}
						position += added;
						if (position >= total) {
							container.addClass('entries-loaded');
						}
					};
				}(this, attached, this.entries(), entries);
				this.watchOther(S.ContentArea, 'scroll_bottom', scrollLoad);
			} else {
				entries.addClass('entries-loaded');
			}
		},
		attachView: function() {
			this._isAttached = true;
			var entries = this._entry_container;
			if (!entries) { return; }
			this.appendEntries(entries);
		},
		check_if_empty: function() {
			var _view = this, _panel = this._panel;
			if (_view.box.entries().length === 0) {
				_panel.addClass('empty');
				// _view._bottom_add_bar.velocity('fadeOut', $.fn.appear.height_change_duration/2, function() {
				// })
			} else {
				_panel.removeClass('empty');
				// _view._bottom_add_bar.velocity('fadeIn', function() {
				// })
			}
		},
		add_allowed_types_bar: function(position, insert_at) {
			var allowed = this.box.allowed_types();
			if (allowed.length === 0) { return ''; }
			var _box = this
, allowed_bar = dom.div('.slot-addable')
			, inner = dom.div('.addable-inner')
			, dropper = allowed_bar
, drop = function(event) {
				dropper.removeClass('drop-active').addClass('uploading');
				// var progress_outer = $(dom.div, {'class':'drop-upload-outer'});
				// var progress_inner = $(dom.div, {'class':'drop-upload-inner'}).css('width', 0);
				// progress_outer.append(progress_inner);
				// dropper.append(progress_outer);
				// this.progress_bar = progress_inner;
				event.stopPropagation();
				event.preventDefault();
				var files = event.dataTransfer.files;
				if (files.length > 0) {
					S.UploadManager.wrap(this, files, insert_at);
				}
				return false;
			}.bind(this)

			, drag_enter = function(event) {
				// var files = event.originalEvent.dataTransfer.files;
				$(this).addClass('drop-active');
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(dropper)

			, drag_over = function(event) {
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(dropper)

			, drag_leave = function(event) {
				$(this).removeClass('drop-active');
				event.stopPropagation();
				event.preventDefault();
				return false;
			}.bind(dropper);

			allowed_bar.addClass(position);
			dropper.get(0).addEventListener('drop', drop, true);
			dropper.bind('dragenter', drag_enter).bind('dragover', drag_over).bind('dragleave', drag_leave);

			$.each(allowed, function(i, allow) {
				var type = allow.type, as = allow.as || type.title;
				var a = dom.a().append(dom.span().text(as)), add_allowed;
				if (type.is_alias()) {
					a.addClass('alias');
					add_allowed = function(type) {
						var d = new Spontaneous.AddAliasDialogue(_box, type, insert_at);
						d.open();
					}.bind(_box, type);
				} else {
					add_allowed = function(type) {
						this.add_content(type, insert_at);
					}.bind(_box, type);
				}
				a.click(add_allowed);
				inner.append(a);
			});
			allowed_bar.data('allowed-count', allowed.length);
			allowed_bar.append(inner, dom.span('.down'));

			return allowed_bar;
		},
		re_sort: function(item) {
			var entries = this.entries(), order = this._entry_container.sortable('toArray'), css_id = item.attr('id'), new_position = 0;
			for (var i = 0, ii = order.length; i < ii; i++) {
				if (order[i] === css_id) { new_position = i; break; }
			}
			var id = css_id.split('-')[1], entry, old_position = 0;

			for (i = 0, ii = entries.length; i < ii; i++) {
				if (entries[i].id() == id) {
					old_position = i;
					entry = entries[i];
					break;
				}
			}
			// move entry inside the array so that we can reliably find its position
			entries.splice(old_position, 1);
			entries.splice(new_position, 0, entry);
			entry.reposition(new_position, function(entry) {
				this.sorted(entry);
			}.bind(this));
		},
		sorted: function(entry) {
		},
		upload_complete: function(values) {
			this.box.entry_added(values);
		},
		upload_progress: function(position, total) {
		},
		entries: function() {
			var entries = [];
			for (var i = 0, ee = this.box.entries(), ii = ee.length;i < ii; i++) {
				var entry = ee[i];
				entries.push(this.view_for_entry(entry));
			}
			return entries;
		}.cache(),

		view_for_entry: function(entry) {
			var view_class = S.Views.PieceView, view, panel;
			if (entry.is_page()) {
				view_class = S.Views.PagePieceView;
			}
			view = new view_class(entry, this); // jshint ignore:line
			return view;
		},
		claim_entry: function(entry) {
			this._subviews.push(entry);
			var div = entry.panel();
			entry.bind('removed', this.entry_removed.bind(this));
			return div.attr('id', this.entry_id(entry)).addClass(this.entry_class());
		},

		entry_id: function(entry) {
			return 'entry-' + entry.content.id();
		},

		entry_class: function() {
			return 'container-'+this.box.schema_id();
		},

		save_path: function() {
			return ['/content', this.id()].join('/');
		},

		add_content: function(content_type, position) {
			this.box.add_entry(content_type, position);
		},

		add_alias: function(target_ids, type, position) {
			this.box.add_alias(target_ids, type, position);
		},

		insert_entry: function(entry, position) {
			this.trigger('entry_added', entry, position);
			var entries = this.entries()
			, w = this.entry_wrappers()
			, e = this.view_for_entry(entry)
			, h = this.claim_entry(e)
			, view = this;
			if (position === -1) {
				entries.push(e);
			} else {
				entries.splice(position, 0, e);
			}
			if (position === -1 || w.length === 0) {
				this._entry_container.append(h);
			} else if (position === 0) {
				this._entry_container.prepend(h);
			} else {
				this.entry_wrappers().slice(position-1, position).after(h);
			}
			if (position === -1) {
				S.ContentArea.scroll_to_bottom($.fn.appear.height_change_duration);
			}
			view.check_if_empty();
			h.hide().appear(function() {
				if (e.content.has_fields()) {
					e.edit();
				}
			});
		},

		remove_entry: function(entry) {
		},
		entry_removed: function(entry) {
			var entries = this.entries();
			for (var i = 0, ii = entries.length; i < ii; i++) {
				if (entries[i] === entry) {
					entries.splice(i, 1);
				}
			}
			this.check_if_empty();
		},
		entry_wrappers: function() {
			return this._entry_container.find('> .'+this.entry_class());
		},
		show_add_after: function(entry, entry_spacer) {
			var bar, position = 0;
			for (var i = 0, entries = this.entries(), ii = entries.length; i < ii; i++) {
				if (entries[i] === entry) {
					position = i;
					break;
				}
			}
			bar = this.add_allowed_types_bar('floating', position + 1);
			if (bar && bar.data('allowed-count') > 0) {
				entry_spacer.addClass('add-entry').append(bar.show());
				if (!entry_spacer.data('auto-height')) {
					entry_spacer.data('auto-height', entry_spacer.height());
				}
				var newHeight = bar.find('.addable-inner').outerHeight() + 11, currentHeight = entry_spacer.outerHeight();
				newHeight = Math.max(newHeight, currentHeight);
				entry_spacer.velocity({height:newHeight}, 200);
			}
		},
		hide_add_after: function(entry, entry_spacer) {
			if (entry_spacer.data('auto-height')) {
				entry_spacer.empty();
				entry_spacer.removeClass('add-entry').velocity({height: entry_spacer.data('auto-height')}, 200);
			}
		}
	});

	return BoxView;

})(jQuery, Spontaneous);

