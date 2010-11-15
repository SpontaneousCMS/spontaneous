console.log('Loading Editing Interface...')

Spontaneous.Editing = (function($, S) {
	var dom = S.Dom, Page = S.Page;

	var Editing = new JS.Singleton({
		include: Spontaneous.Properties,

		init: function(container) {
			this.container = $(dom.div, {'id' : 'data_pane'});
			this.container.hide();
			this.page = false;
			container.append(this.container);
			return this;
		},
		display: function(page) {
			this.goto(page);
			this.container.fadeIn();
		},
		goto: function(page) {
			if (!page) { return; }
			console.log('>>>', page)
			S.Ajax.get('/page/{id}'.replace('{id}', page.id), this, this.page_loaded);
			this.set('location', page);
		},
		page_loaded: function(page_data) {
			if (this.page) { this.page.unload(); }
			var page = new Page(page_data);
			this.container.empty();
			this.container.append(page.panel());
			this.page = page;
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
