console.log('Loading Slot...')

Spontaneous.Slot = (function($, S) {
	var dom = S.Dom;

	var Slot = function(content, dom_container) {
		this.content = content;
		this.dom_container = dom_container;
		this.id = content.id;
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
						this.add_content(type);
					}.bind(_slot, type);
					var a = $(dom.a).click(add_allowed).text(type.title);
					allowed_bar.append(a)
				});
				allowed_bar.append($(dom.span, {'class':'down'}));
				panel.append(allowed_bar);
				var entries = $(dom.div, {'class':'slot-entries'});
				panel.append();
				for (var i = 0, ee = this.entries(), ii = ee.length;i < ii; i++) {
					var entry = ee[i];
					entries.append(entry.panel());
				}
				panel.append(entries);
				panel.hide();
				this.dom_container.append(panel)
				this._panel = panel;
			}
			return this._panel;
		},
		add_content: function(content_type) {
			console.log("Slot#add_content", content_type)
			this.add_entry(content_type);
		}
	});

	return Slot;

})(jQuery, Spontaneous);
