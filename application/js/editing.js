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
			this.container.show().fadeOut(0)
			S.Ajax.get('/page/{id}'.replace('{id}', page.id), this.page_loaded.bind(this));
			this.set('location', page);
		},
		page_loaded: function(page_data) {
			var page = this.get('page');
			if (page) { page.unload(); }
			page = new Page(page_data);
			view = new S.Views.PageView(page);
			this.container.empty();
			this.container.append(view.panel());
			this.set('page', page);
			this.container.fadeIn(300);
		},
		hide: function() {
			this.container.hide();
		},
		show: function() {
			this.container.show();
		}
	});
	return Editing;
})(jQuery, Spontaneous);
