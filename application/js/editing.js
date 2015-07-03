// console.log('Loading Editing Interface...')

Spontaneous.Editing = (function($, S) {
	var dom = S.Dom, Page = S.Page;

	var Editing = new JS.Singleton({
		include: Spontaneous.Properties,

		init: function(container) {
			this.container = dom.div('#data_pane');
			this.container.hide();
			container.append(this.container);
			return this;
		},
		display: function(page) {
			this.goto_page(page);
		},
		goto_page: function(page) {
			if (!page) { return; }
			this.container.show().velocity('fadeOut', 0);
			S.Ajax.get(['/page', page.id].join('/'), this.page_loaded.bind(this));
			this.set('location', page);
		},
		page_loaded: function(page_data) {
			var self = this
			, page = self.get('page')
			, view = self.get('view')
			, panel = self.container;
			if (page) { page.unload(); }
			if (view) { view.unload(); }
			page = new Page(page_data);
			page.watch('path', self.path_updated.bind(self));
			view = new S.Views.PageView(page);
			panel.animate({opacity: 0}, 0, function() {
				panel.empty().show();
				panel.append(view.panel());
				view.onDOMAttach();
				self.set('page', page);
				self.set('view', view);
				panel.velocity({opacity: 1}, 200);
			});
		},
		path_updated: function(path) {
			this.set('path', path);
		},
		path: function() {
			var path = this.get('path');
			if (path) {
				return path;
			} else {
				return this.get('page').get('path');
			}
		},
		hide: function() {
			this.container.hide();
		},
		show: function() {
			this.container.show();
		},
		showLoading: function() {
			this.container.velocity({'opacity': 0}, 100);
		},
		hideLoading: function() {
			// let the page_loaded function deal with actually showing the new page
		}
	});
	return Editing;
})(jQuery, Spontaneous);
