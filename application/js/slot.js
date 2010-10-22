
console.log('Loading Slot...')

Spontaneous.Slot = (function($, S) {
	var dom = S.Dom;

	var Slot = function(container, entry) {
		this.container = container;
		this.entry = entry;
		this.id = entry.id;
		this.type = entry.type;
		this.entries = entry.entries;
		this.is_page = entry.is_page;
		console.log('slot', this);
	};
	Slot.prototype = $.extend({}, S.FacetEntry.prototype, {
		// preview_elements: ['title_bar', 'field_list', 'contents_list', 'bottom'],
		// slot only
		tab: function() {
			var load = (function(slot) {
				return function() {
					slot.container.show(slot);
				};
			})(this);
			this.tab_element = $(dom.li, {'class':'tab', 'id':'content-' + this.id}).click(load);
			this.tab_element.text(this.entry.name);
			return this.tab_element;
		},
		activate_tab: function() {
			this.tab_element.addClass('active');
		},
		title_bar: function() {
			return '';
		},
		make_draggable: function() {
			this._preview_panel.make_draggable();
		},
		make_preview_draggable: function() {
			// alert("slot#make_preview_draggable")
			// this.parts['content_list'].make_draggable();
			console.log('preview panel', this.preview_panel());
			this.preview_panel().make_preview_draggable();
		},
		show_entry_add: function() {
			return true;
		}
	});
	return Slot;
})(jQuery, Spontaneous);
