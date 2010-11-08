console.log('Loading Slot...')

Spontaneous.Slot = (function($, S) {
	var dom = S.Dom;

	var Slot = new JS.Class(Spontaneous.Content, {

		initialize: function(content, dom_container) {
			this.callSuper(content);
			this.dom_container = dom_container;
		},

		name: function() {
			return this.content.name;
		},
		activate: function() {
			// console.log('Slot#activate', this.name());
			$('> .slot-content', this.dom_container).hide();
			this.panel().show();
		},

		panel: function() {
			if (!this._panel) {
				var panel = $(dom.div, {'class': 'slot-content'});
				if (this.has_fields()) {
					var fields = new Spontaneous.FieldPreview(this, '');
					panel.append(fields.panel())
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

				var _slot = this;
				$.each(allowed, function(i, type) {
					var add_allowed = function(type) {
						this.add_content(type, 0);
					}.bind(_slot, type);
					var a = $(dom.a).click(add_allowed).text(type.title);
					allowed_bar.append(a)
				});
				allowed_bar.append($(dom.span, {'class':'down'}));
				panel.append(allowed_bar);
				var entries = $(dom.div, {'class':'slot-entries'});
				// panel.append();
				for (var i = 0, ee = this.entries(), ii = ee.length;i < ii; i++) {
					var entry = ee[i];
					entries.append(this.claim_entry(entry.panel()));
				}
				panel.append(entries);
				panel.hide();
				this.dom_container.append(panel)
				this._panel = panel;
				this._entry_container = entries;
			}
			return this._panel;
		},

		upload_complete: function(values) {
			console.log('Slot.upload_complete', values);
			this.insert_entry(this.wrap_entry(values.entry), values.position);
		},
		upload_progress: function(position, total) {
			console.log('Slot.upload_progress', position, total);
		},
		claim_entry: function(entry) {
			return entry.addClass(this.entry_class());
		},

		entry_class: function() {
			return 'entry-'+this.id();
		},

		add_content: function(content_type, position) {
			this.add_entry(content_type, position, this.insert_entry.bind(this));
		},
		insert_entry: function(entry, position) {
			var w = this.entry_wrappers(), e = this.claim_entry(entry.panel()), h;
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

	return Slot;

})(jQuery, Spontaneous);
