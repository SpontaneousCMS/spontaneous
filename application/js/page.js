console.log('Loading Page...')

Spontaneous.Page = (function($, S) {
	var dom = S.Dom, Slot = S.Slot;

	var URLBar = function(page) {
		this.page = page;
	};
	URLBar.prototype = {
		panel: function() {
			this.panel = $(dom.div, {'id': 'url-panel'}).text("url edit: " + this.page.url)
			return this.panel;
		}
	};
	var FunctionBar = function(page) {
		this.page = page;
	};
	FunctionBar.prototype = {
		panel: function() {
			this.panel = $(dom.div, {'id': 'page-info'});
			this.panel.append($('<h1/>').text(this.page.title()))
			this.panel.append($('<h3/>').text(this.page.path))
			return this.panel;
		}
	};
	var Page = function(content) {
		this.content = content;
		this.path = content.path;
		this.entries = content.entries;
	};
	Page.prototype = $.extend({}, Spontaneous.Content, {
		title: function() {
			return this.fields().title.value();
		},
		panel: function() {
			this.panel = $(dom.div, {'id':'page-content'});
			this.panel.append(new FunctionBar(this).panel());
			this.panel.append(new Spontaneous.FieldPreview(this, 'page-fields').panel());
			this.panel.append(new Spontaneous.SlotContainer(this, 'page-slots').panel());
			return this.panel;
		},
		depth: function() {
			// depth in this case refers to content depth which is always 0 for pages
			return 0;
		}
	});

	return Page;
})(jQuery, Spontaneous);
