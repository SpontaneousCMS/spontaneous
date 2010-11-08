console.log('Loading Slot...')

Spontaneous.Slot = (function($, S) {
	var dom = S.Dom;

	var Slot = function(content, dom_container) {
		this.content = content;
		this.dom_container = dom_container;
	};

	Slot.prototype = $.extend({}, Spontaneous.Content, {
		name: function() {
			return this.content.name;
		},
		activate: function() {
			console.log('Slot#activate', this.name());
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

		claim_entry: function(entry) {
			return entry.addClass(this.entry_class());
		},

		entry_class: function() {
			return 'entry-'+this.id();
		},

		add_content: function(content_type, position) {
			this.add_entry(content_type, position, function(entry, position) {
				var w = this.entry_wrappers(), e = this.claim_entry(entry.panel()), h;
				if (w.length > 0) {
					this.entry_wrappers().slice(position, position+1).before(e);
				} else {
					this._entry_container.append(e);
				}
				e.hide().slideDown(300);
			}.bind(this));
		},

		entry_wrappers: function() {
			return this._entry_container.find('> .'+this.entry_class())
		}
	});

	return Slot;

})(jQuery, Spontaneous);
