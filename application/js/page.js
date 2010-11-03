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
	var ContentPanel = function(page) {
		this.page = page;
	};
	ContentPanel.prototype = $.extend({}, {
		slot_panels: {},
		panel: function() {
			this.panel = $(dom.div, {'id': 'content-panel'});
			this.tabs = $(dom.ul, {'class': 'tabs'})
			this.slots = [];
			this.slot_panels = {};
			console.log('page', this.page);
			for (var i = 0; i < this.page.entries.length; i++) {
				var slot = new Slot(this, this.page.entries[i]);
				if (!slot.is_page) {
					this.slots.push(slot);
					this.tabs.append(slot.tab());
				}
			};
			this.panel.append(this.tabs);
			this.wrapper = $(dom.div, {'id': 'content-wrapper'});;
			this.panel.append(this.wrapper);
			console.log('**** about to show', this.slots)
			if (this.slots.length > 0) { this.show(this.slots[0]); }
			return this.panel;
		},
		show: function(slot) {
			console.log('showing', slot, this.slot_panels);
			this.tabs.find('li').removeClass('active');
			this.wrapper.children('.entry-container').hide();
			if (!this.slot_panels[slot.id]) {
				this.slot_panels[slot.id] = slot.preview();
				console.log(this.slot_panels[slot.id])
				this.wrapper.append(this.slot_panels[slot.id]);
			}
			this.slot_panels[slot.id].show();
			slot.activate_tab();
		}
	});
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
			// this.panel.append(new URLBar(this).panel());
			this.panel.append(new FunctionBar(this).panel());
			this.panel.append(new Spontaneous.FieldPreview(this, 'page-fields').panel());
			this.panel.append(new Spontaneous.SlotContainer(this, 'page-slots').panel());
			// this.panel.append(new ContentPanel(this).panel());
			return this.panel;
		}
	});

	return Page;
})(jQuery, Spontaneous);
