console.log('Loading PageEntry...')

Spontaneous.PageEntry = (function($, S) {
	var dom = S.Dom;

	var PageEntry = function(container, entry) {
		console.log('page entry', entry, this.id);
		this.entry = entry;
		this.id = entry.id;
		this.entries = [];
		this.is_page = entry.is_page;
	};
	PageEntry.prototype = $.extend({}, S.FacetEntry.prototype, {
		model_name: 'page',
		preview_elements: ['title_bar', 'page_link', 'field_list', 'contents_list', 'bottom'],
		preview_panel:function() {
			if (!this._preview_panel) {
				this._preview_panel = new PageEntry.PagePreviewPanel(this);
			}
			return this._preview_panel;
		}
	});
	PageEntry.PagePreviewPanel = function(entry) {
		this.entry = entry;
	};
	PageEntry.PagePreviewPanel.prototype = $.extend({}, S.FacetEntry.FacetPreviewPanel.prototype, {
		page_link: function() {
			var edit_page = (function(page_entry) {
				return function() {
					alert('loading page ' + page_entry.entry.id)
				};
			})(this);
			var page_link = $(dom.a).click(edit_page).text(this.entry.field("title").get('value'));
			this.entry.field('title').add_listener('value', function(title) {
				page_link.html(title);
			});
			return $(dom.div, {'class':'page-entry-link'}).append($(dom.h3).append(page_link));
		},
		facet_wrap_class: function() {
			return 'facet page depth-'+this.entry.depth();
		},
		contents_list: function() {
			return '';
		}
	});
	return PageEntry;
})(jQuery, Spontaneous);
