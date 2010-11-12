console.log('Loading Page...')

Spontaneous.Page = (function($, S) {
	var dom = S.Dom, Slot = S.Slot;

	var FunctionBar = function(page) {
		this.page = page;
	};
	FunctionBar.prototype = {
		panel: function() {
			this.panel = $(dom.div, {'id': 'page-info'});
			this.panel.append($('<h1/>').text(this.page.title()))
			var path_wrap = $(dom.div, {'class':'path'})
		
			path_wrap.append($('<h3/>').text(this.page.path).click(function() {
				if (this.page.path !== '/') {
					this.open_url_editor();
				}
			}.bind(this)));
			path_wrap.append($(dom.div, {'class':'edit'}));
			this.panel.append(path_wrap);
			this.path_wrap = path_wrap
			return this.panel;
		},
		open_url_editor: function() {
			var view = $('h3', this.panel), edit = $('.edit', this.panel);
			view.hide();
			edit.empty();
			var path = [""];
			var parts = this.page.path.split('/')
			var slug = parts.pop();
			parts.shift(); // remove empty entry caused by leading '/'
			edit.append($(dom.span).text('/'))
			for (var i = 0, ii = parts.length; i < ii; i++) {
				var p = parts[i];
				path.push(p)
				edit.append($(dom.a).text(p).attr('href', path.join('/')))
				edit.append($(dom.span).text('/'))
			}
			var input = $(dom.input, {'type':'text'}).val(slug);
			
			edit.append(input);
			var submit = function() {
				// test url for uniqueness
				// if it's safe then save it
				console.log('saving', input.val())
				this.save(input.val());
			}.bind(this);
			edit.append($(dom.a, {'class':'button'}).text('Save').click(submit));
			input.keydown(function(event) {
				console.log(event)
				if (event.keyCode === 13) {
					submit();
				}
			});
		},
		save: function(slug) {
			Spontaneous.Ajax.post('/slug/'+this.page.id(), {'slug':slug}, this, this.save_complete);
		},
		save_complete: function(response) {
			console.log('FunctionBar.save_complete', response)
		}
	};
	var Page = new JS.Class(Spontaneous.Content, {
		initialize: function(content) {
			this.callSuper(content);
			this.path = content.path;
		},
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
