console.log('Loading Box...')

Spontaneous.Box = (function($, S) {
	var dom = S.Dom;

	var Box = new JS.Class(Spontaneous.Content, {

		initialize: function(content, container, dom_container) {
			this.container = container;
			this.callSuper(content);
			this.dom_container = dom_container;
		},

		name: function() {
			return this.type().title;
		},
		activate: function() {
			$('> .slot-content', this.dom_container).hide();
			this.panel().show();
		},

		type: function() {
			if (!this._type) {
				this._type = this.container.type().box_prototype(this.content.id)
			}
			return this._type;
		},

		depth: function() {
			return 'box';
		},



		panel: function() {
			if (!this._panel) {
				var panel = $(dom.div, {'class': 'slot-content'});
				if (this.has_fields()) {
					var w = $(dom.div, {'class':'box-fields'});
					var fields = new Spontaneous.FieldPreview(this, '');
					var preview_area = this.create_edit_wrapper(fields.panel());

					w.append(preview_area);
					panel.append(w);
				}

				var allowed = this.allowed_types();
				var allowed_bar = $(dom.div, {'class':'slot-addable'});
				var dropper = allowed_bar;
				var drop = function(event) {
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
						S.UploadManager.wrap(this, files);
					}
					return false;
				}.bind(this);

				var drag_enter = function(event) {
					// var files = event.originalEvent.dataTransfer.files;
					// console.log(event.originalEvent.dataTransfer, files)
					$(this).addClass('drop-active');
					event.stopPropagation();
					event.preventDefault();
					return false;
				}.bind(dropper);

				var drag_over = function(event) {
					event.stopPropagation();
					event.preventDefault();
					return false;
				}.bind(dropper);

				var drag_leave = function(event) {
					$(this).removeClass('drop-active');
					event.stopPropagation();
					event.preventDefault();
					return false;
				}.bind(dropper);

				dropper.get(0).addEventListener('drop', drop, true);
				dropper.bind('dragenter', drag_enter).bind('dragover', drag_over).bind('dragleave', drag_leave);

				var _box = this;
				$.each(allowed, function(i, type) {
					var add_allowed = function(type) {
						this.add_content(type, 0);
					}.bind(_box, type);
					var a = $(dom.a).click(add_allowed).text(type.title);
					allowed_bar.append(a)
				});
				allowed_bar.append($(dom.span, {'class':'down'}));
				panel.append(allowed_bar);
				var entries = $(dom.div, {'class':'slot-entries'});
				// panel.append();
				for (var i = 0, ee = this.entries(), ii = ee.length;i < ii; i++) {
					var entry = ee[i];
					entries.append(this.claim_entry(entry));
				}
				entries.sortable({
					items:'> .'+this.entry_class(),
					handle: '.title-bar',
					axis:'y',
					distance: 5,
					tolerance: 'pointer',
					scrollSpeed: 40,
					containment: 'parent',
					stop: function(event, ui) {
						this.re_sort(ui.item);
					}.bind(this)
				})
				panel.append(entries);
				panel.hide();
				this.dom_container.append(panel)
				this._panel = panel;
				this._entry_container = entries;
			}
			return this._panel;
		},
		re_sort: function(item) {
			var order = this._entry_container.sortable('toArray'), css_id = item.attr('id'), position = 0;
			// console.log('Slot.resort', item, order, id);
			for (var i = 0, ii = order.length; i < ii; i++) {
				if (order[i] === css_id) { position = i; break; }
			}
			var id = css_id.split('-')[1], entry;

			for (var i = 0, entries = this.entries(), ii = entries.length; i < ii; i++) {
				if (entries[i].id() == id) { entry = entries[i]; break; }
			}
			// console.log(position, id, entry);
			entry.reposition(position, function(entry) {
				this.sorted(entry)
			}.bind(this));
		},
		sorted: function(entry) {
			// console.log('Slot.sorted', entry);
		},
		upload_complete: function(values) {
			console.log('Box.upload_complete', values);
			this.insert_entry(this.wrap_entry(values.entry), values.position);
		},
		upload_progress: function(position, total) {
			console.log('Box.upload_progress', position, total);
		},
		claim_entry: function(entry) {
			var div = entry.panel();
			return div.attr('id', this.entry_id(entry)).addClass(this.entry_class());
		},
		entry_id: function(entry) {
			return "entry-" + entry.id();
		},
		entry_class: function() {
			return 'container-'+this.id();
		},

		add_content: function(content_type, position) {
			this.add_entry(content_type, position, this.insert_entry.bind(this));
		},
		add_entry: function(type, position, callback) {
			Spontaneous.Ajax.post(['/add', this.container.id(), this.id(), type.type].join('/'), {}, this, function(result) {
				this.entry_added(result, callback);
			});
		},
		save_path: function() {
			return ['/savebox', this.container.id(), this.id()].join('/');
		},
		insert_entry: function(entry, position) {
			var w = this.entry_wrappers(), e = this.claim_entry(entry), h;
			if (w.length > 0) {
				this.entry_wrappers().slice(position, position+1).before(e);
			} else {
				this._entry_container.append(e);
			}
			e.hide().slideDown(300);
		},
		entry_wrappers: function() {
			return this._entry_container.find('> .'+this.entry_class())
		}
	});

	return Box;

})(jQuery, Spontaneous);
