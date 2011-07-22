// console.log('Loading Page...')

Spontaneous.Page = (function($, S) {
	var dom = S.Dom, Slot = S.Slot;

	var FunctionBar = function(page) {
		this.page = page;
	};
	FunctionBar.prototype = {
		panel: function() {
			this.panel = dom.div('#page-info');
			this.title = $('<h1/>');
			this.set_title();
			this.panel.append(this.title);
			var path_wrap = dom.div('.path');

			this.page.title_field().add_listener('value', function(t) {
				this.set_title(t);
			}.bind(this));

			var path_text = $()
			var path_text = $('<h3/>').text(this.page.path).click(function() {
				if (this.page.path !== '/') {
					this.open_url_editor();
				}
			}.bind(this));
			path_wrap.append(path_text, dom.div('.edit'));

			this.page.add_listener('path', function(path) {
				path_text.text(path);
			}.bind(this));

			this.panel.append(path_wrap);
			this.path_wrap = path_wrap
			return this.panel;
		},
		set_title: function(title) {
			title = title || this.page.title();
			this.title.text(title);
			if (this.page.content.hidden) {
				this.title.append(dom.span().text(' (hidden)'));
			}
		},
		unavailable_loaded: function(response) {
			var u = {};
			for (var i = 0, ii = response.length; i < ii; i++) {
				u[response[i]] = true;
			}
			this.unavailable = u;
		},
		open_url_editor: function() {
			this.unavailable = false;
			Spontaneous.Ajax.get(['/slug', this.page.id(), 'unavailable'].join('/'), this, this.unavailable_loaded);
			this.panel.animate({'height': '+=14'}, 200, function() {
				var view = $('h3', this.panel), edit = $('.edit', this.panel);
				view.hide();
				edit.hide().empty();
				var path = [""], parts = this.page.get('path').split('/'), slug = parts.pop();
				parts.shift(); // remove empty entry caused by leading '/'
				edit.append(dom.span().text('/'))
				for (var i = 0, ii = parts.length; i < ii; i++) {
					var p = parts[i];
					path.push(p)
					edit.append(dom.a('.path').text(p).attr('href', path.join('/')).click(function() {
						S.Location.load_path($(this).attr('href'));
						return false;
					}));
					edit.append(dom.span().text('/'));
				}
				var input_and_error = dom.span('.input-error');
				var input = dom.input({'type':'text', 'autofocus':'autofocus'}).val(slug).select();
				var error = dom.span().text('Duplicate URL').hide();
				input_and_error.append(input);
				input_and_error.append(error);
				edit.append(input_and_error);
				var submit = function() {
					this.save(input.val());
				}.bind(this);
				edit.append(dom.a('.button.save').text('Save').click(submit));
				edit.append(dom.a('.button.cancel').text('Cancel').click(this.close.bind(this)));
				input.keyup(function(event) {
					if (event.keyCode === 13) {
						submit();
					} else {
						var v = this.input.val();
						// do some basic cleanup -- proper cleanup is done on the server-side
						v = v.toLowerCase().replace(/['"]/g, '').replace(/\&/, 'and');
						v = v.replace(/[^\w0-9+]/g, '-').replace(/(\-+|\s+)/g, '-').replace(/(^\-)/, '');
						this.input.val(v);
						if (v === '') {
								this.show_path_error('Invalid URL');
						} else {
							if (this.unavailable[v]) {
								this.show_path_error();
							} else {
								this.hide_path_error();
							}
						}
					}
				}.bind(this)).keydown(function(event) {
					if (event.keyCode === 27) { this.close(); }
				}.bind(this));
				this.input = input;
				this.error = error;
				edit.fadeIn(200);
			}.bind(this));
		},
		show_path_error: function(error_text) {
			error_text = (error_text || "Duplicate URL");
			this.error.text(error_text).fadeIn(100);
			this.input.addClass('error');
		},
		hide_path_error: function(error_text) {
			this.error.fadeOut(100);
			if (this.input.hasClass('error')) { this.input.removeClass('error'); }
		},
		save: function(slug) {
			Spontaneous.Ajax.post('/slug/'+this.page.id(), {'slug':slug}, this, this.save_complete);
		},

		save_complete: function(response, status, xhr) {
			if (status === 'success') {
				this.hide_path_error();
				var view = $('h3', this.panel), edit = $('.edit', this.panel);
				this.page.path = response.path;
				view.text(response.path);
				this.close();
				// HACK: see preview.js (Preview.display)
				Spontaneous.Location.set('path', this.page.path)
			} else {
				if (xhr.status === 409) { // duplicate path
					this.show_path_error();
				}
				if (xhr.status === 406) { // empty path
					this.show_path_error('Invalid URL');
				}
			}
		},
		close: function() {
			var view = $('h3', this.panel), edit = $('.edit', this.panel);
			view.show();
			edit.hide();
			this.panel.animate({'height': '-=14'}, 200)
		}
	};
	var Page = new JS.Class(Spontaneous.Content, {
		initialize: function(content) {
			this.callSuper(content);
			this.path = content.path;
			this.set('path', content.path);
		},

		save_complete: function(values) {
			this.set('slug', values.slug);
			this.set('path', values.path);
		},
		panel: function() {
			this.panel = dom.div('#page-content');
			this.panel.append(new FunctionBar(this).panel());

			var fields = dom.div('#page-fields')
			var fp = new Spontaneous.FieldPreview(this, '');
			var p = fp.panel();
			p.prepend(dom.div('.overlay'))

			var preview_area = this.create_edit_wrapper(p);
			fields.append(preview_area)
			this.panel.append(fields);
			this.panel.append(new Spontaneous.BoxContainer(this, 'page-slots').panel());
			this.fields_preview = p;
			return this.panel;
		},
		mouseover: function() {
			if (this.fields_preview) {
				this.fields_preview.addClass('hover');
			}
		},
		mouseout: function() {
			if (this.fields_preview) {
				this.fields_preview.removeClass('hover');
			}
		},
		depth: function() {
			// depth in this case refers to content depth which is always 0 for pages
			return 0;
		}
	});

	return Page;
}(jQuery, Spontaneous));
