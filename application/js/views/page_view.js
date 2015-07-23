// console.log('Loading Page...')

Spontaneous.Views.PageView = (function($, S, document) {
	var dom = S.Dom, user = S.User, ajax = S.Ajax, Types = S.Types;

	var FunctionBar = function(page) {
		this.page = page;
	};
	FunctionBar.prototype = {
		panel: function() {
			var self = this;
			var isAlias = self.isAlias();
			this.panel = dom.div('#page-info');
			if (isAlias) {
				self.panel.addClass('page-info-alias-type');
			}
			var h1 = $('<h1/>');
			self.title = dom.span();
			h1.append(self.title);
			self.set_title();
			self.panel.append(h1);
			self.panel.append(self.aliasTargetLink());
			var path_wrap = dom.div('.path');

			self.page.title_field().watch('value', function(t) {
				self.set_title(t);
			});

			var path_text = dom.h3('.path').text(self.page.get('path'));

			if (isAlias) {
				path_text.addClass('path-read-only');
			}
			path_wrap.append(path_text);

			if (!isAlias && !self.page.is_root()) {
				path_text.click(function() {
					self.open_url_editor();
				});

				var resync = dom.a({ 'title':'Sync the path to the page title'}).click(function() {
					ajax.put(['/page', self.page.id(), 'slug/sync'].join('/'), {}, self.save_complete.bind(self));
				});
				path_wrap.append(dom.h3('.titlesync').append(resync));
			}

			// path_wrap.append(dom.div('.path-spacer'));

			if (user.is_developer()) {
				// var uid_text = dom.h3('.developer.uid' + (!self.page.content.uid ? '.missing' : '')).text('#' + (self.page.content.uid || "----")).click(function() {
				// 	self.open_uid_editor();
				// }.bind(self));

				var mark_modified = self.touch_page.bind(self);
				var buttons = dom.div('.page-buttons.developer').append(dom.button().text('Mark modified').click(mark_modified));
				var dev_desc = dom.a('.developer.type-information', {href:self.page.developer_edit_url()}).text(self.page.developer_description());
				buttons.prepend(dev_desc);
				self.panel.append(buttons);
			}
			var page_aliases = self.pageAliasesPanel();
			self.panel.append(page_aliases);

			path_wrap.append(dom.div('.edit'));

			self.page.watch('path', function(path) {
				path_text.text(path);
			});

			self.panel.append(path_wrap);
			self.path_wrap = path_wrap;
			return self.panel;
		},
		isAlias: function() {
			return this.page.type().is_alias();
		},
		aliasTargetLink: function() {
			var self = this;
			if (!self.isAlias()) {
				return '';
			}
			var target = self.page.content.target;
			var viewAlias = function(e) {
				e.stopPropagation();
				S.Location.load_id(target.page_id);
			};
			var $targetTitle = dom.span('.page-alias-link--title').text(target.title);
			var $targetPath = dom.span('.page-alias-link--path').text(target.path);
			return dom.div('.page-alias-link').append($targetTitle, $targetPath).click(viewAlias);
		},
		pageAliasesPanel: function() {
			var $wrap = dom.div('.page-aliases');
			var aliases = this.page.content.aliases;
			if (aliases.length === 0) {
				return $wrap;
			}
			var showAlias = function(alias) {
				return function(event) {
					event.stopPropagation();
					S.Location.load_id(alias.page_id);
				};
			};

			var $label = dom.div('.page-aliases--label').text(aliases.length + ' alias' + (aliases.length > 1 ? 'es' : ''))
			var $list = dom.div('.page-aliases--list');
			$wrap.append($label, $list);
			aliases.forEach(function(a) {
				var boxType = Types.boxPrototype(a.box);
				var $title = dom.div('.page-alias--title').text(a.title);
				var path = a.path + ' [' + boxType.title + ']';
				var $path = dom.div('.page-alias--path').text(path);
				var $el =  dom.div('.page-alias').append($title, $path).click(showAlias(a));
				$list.append($el);
			});
			var eventName = 'click.alias_list_off';
			var hide = function() { $wrap.removeClass('visible'); };
			$wrap.click(function(e) {
				$wrap.toggleClass('visible');
				e.stopPropagation();
				if ($wrap.hasClass('visible')) {
					$(document).one(eventName, hide);
				} else {
					$(document).off(eventName);
				}
			});
			return $wrap;
		},
		unload: function() {
			// fit with the view prototype
		},
		onDOMAttach: function() {
		},
		set_title: function(title) {
			var self = this;
			title = title || this.page.title();
			this.title.html(title);
			if (this.page.content.hidden) {
				self.title.append(dom.span('.page-is-hidden').text(' (hidden)'));
			}
			var maxHeight = 36;
			window.setTimeout(function()  {
				var t = self.title.parent()
					, height = function() { return t.height(); }
					, fs = window.parseInt(t.css('font-size'), 10);
				while (height() > maxHeight && fs > 10) {
					t.css('font-size', --fs);
				}
			}, 0);
		},
		unavailable_loaded: function(response) {
			var u = {};
			for (var i = 0, ii = response.length; i < ii; i++) {
				u[response[i]] = true;
			}
			this.unavailable = u;
		},
		open_uid_editor: function() {
			this.panel.velocity({'height': '+=14'}, { duration: 200, complete: function() {
				var view = $('h3', this.panel), edit = $('.edit', this.panel);
				view.hide();
				edit.hide().empty();
				var input = dom.input({'type':'text', 'autofocus':'autofocus'}).val(this.page.content.uid).select();
				var input_and_error = dom.div('.input-error.uid-input');
				var hash = dom.div('.hash').text('#');
				var label = dom.label().text('UID');
				var submit = function() {
					this.save_uid(input.val());
				}.bind(this);
				input_and_error.append(hash, input);
				edit.append(label, input_and_error);
				edit.append(dom.a('.button.save').text('Save').click(submit));
				edit.append(dom.a('.button.cancel').text('Cancel').click(this.close.bind(this)));
				input.bind('keydown.uideditor', function(event) {
					var s_key = 83, esc_key = 27;
					if ((event.ctrlKey || event.metaKey) && event.keyCode === s_key) {
						submit();
						return false;
					}
				}.bind(this));
				input.keyup(function(event) {
					if (event.keyCode === 13) {
						submit();
					} else {
						var v = input.val();
						// do some basic cleanup -- proper cleanup is done on the server-side
						v = v.toLowerCase().replace(/['"]/g, '');
						v = v.replace(/[^a-z0-9_]/g, '_').replace(/(\_+|\s+)/g, '_').replace(/(^\-)/, '');
						input.val(v);
					}
				}.bind(this)).keydown(function(event) {
					if (event.keyCode === 27) { this.close(); }
				}.bind(this));
				edit.velocity('fadeIn', 200);
			}.bind(this)});
		},
		touch_page: function(event) {
			var $btn = $(event.target).addClass('request-running').attr('disabled', true);
			Spontaneous.Ajax.put(['/page',this.page.id(), 'touch'].join('/'), {}, this.touch_page_complete.bind(this, $btn));
		},
		touch_page_complete: function($btn, response, status, xhr) {
			$btn.removeClass('request-running').attr('disabled', false);
		},
		save_uid: function(uid) {
			Spontaneous.Ajax.put(['/page',this.page.id(), 'uid'].join('/'), {'uid':uid}, this.uid_save_complete.bind(this));
		},
		uid_save_complete: function(response, status, xhr) {
			if (status === 'success') {
				var view = $('h3.uid', this.panel), edit = $('.edit', this.panel), uid = (response.uid === '' ? '----' : response.uid);
				// nasty but the value is only used for display
				this.page.content.uid = response.uid;
				view.text('#'+uid);
				this.close();
			}
		},
		open_url_editor: function() {
			this.unavailable = false;
			this.url_editor_open = true;
			Spontaneous.Ajax.get(['/page', this.page.id(), 'slug/unavailable'].join('/'), this.unavailable_loaded.bind(this));
			this.panel.velocity({'height': '+=14'}, {duration: 200, complete: function() {
				var view = $('h3', this.panel), edit = $('.edit', this.panel), spacer = $('.path-spacer', this.panel);
				spacer.add(view).hide();
				edit.hide().empty();
				var path = [''], parts = this.page.get('path').split('/'), slug = parts.pop();
				parts.shift(); // remove empty entry caused by leading '/'
				edit.append(dom.span().text('/'));
				var click = function() {
					S.Location.load_path($(this).attr('href'));
					return false;
				};
				for (var i = 0, ii = parts.length; i < ii; i++) {
					var p = parts[i];
					path.push(p);
					edit.append(dom.a('.path').text(p).attr('href', path.join('/')).click(click));
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

				var last_slug = slug;
				var close = function() { this.close(); }.bind(this);

				edit.append(dom.a('.button.save').text('Save').click(submit));
				edit.append(dom.a('.button.cancel').text('Cancel').click(close));

				input.bind('keydown.urleditor', function(event) {
					var s_key = 83, esc_key = 27;
					if ((event.ctrlKey || event.metaKey) && event.keyCode === s_key) {
						submit();
						return false;
					}
				}.bind(this));

				input.keyup(function(event) {
					if (event.keyCode === 13) {
						submit();
					} else {
						var i = this.input, v = i.val(), i0 = i[0], se = i0.selectionEnd;
						if (v !== last_slug) {
							// do some basic cleanup -- proper cleanup is done on the server-side
							v = v.toLowerCase().replace(/['"]/g, '').replace(/\&/, 'and');
							v = v.replace(/[^\w0-9+]/g, '-').replace(/(\-+|\s+)/g, '-').replace(/(^\-)/, '');
							if (last_slug.length === v.length) {
								se -= 1;
							}
							i.val(v);
							i0.selectionStart = i0.selectionEnd = se;
							last_slug = v;
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
					}
				}.bind(this)).keydown(function(event) {
					if (event.keyCode === 27) { close(); }
				}.bind(this));

				edit.velocity({opacity: 1}, {duration: 200, display: 'flex', complete: function() {
					input.focus();
				}});
				this.input = input;
				this.error = error;
			}.bind(this)});
		},
		show_path_error: function(error_text) {
			error_text = (error_text || 'Duplicate URL');
			this.error.text(error_text).velocity('fadeIn', 100);
			this.input.addClass('error');
		},
		hide_path_error: function(error_text) {
			if (this.error) { this.error.velocity('fadeOut', 100); }

			if (this.input && this.input.hasClass('error')) { this.input.removeClass('error'); }
		},
		save: function(slug) {
			Spontaneous.Ajax.put(['/page',this.page.id(), 'slug'].join('/'), {'slug':slug}, this.save_complete.bind(this));
		},

		save_complete: function(response, status, xhr) {
			if (status === 'success') {
				if (this.url_editor_open) {

					this.hide_path_error();
					var view = $('h3.path', this.panel), edit = $('.edit', this.panel);
					this.close();
				}
				this.page.set('path', response.path);
				this.page.set('slug', response.slug);
				// HACK: see preview.js (Preview.display)
				Spontaneous.Location.set('path', this.page.get('path'));
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
			this.url_editor_open = false;
			var view = $('h3', this.panel), edit = $('.edit', this.panel), spacer = $('.path-spacer', this.panel);
			view.add(spacer).show();
			edit.hide();
			this.panel.velocity({'height': '-=14'}, 200);
		}
	};
	var PageView = new JS.Class(Spontaneous.Views.View, {
		initialize: function(page) {
			this.page = page;
			this.callSuper(page);
		},

		panel: function() {
			this.panel = dom.div('#page-content');
			if (this.page.hidden()) {
				this.panel.addClass('hidden');
			}
			var functionbar = new FunctionBar(this.page);
			this._subviews.push(functionbar);
			this.panel.append(functionbar.panel());

			var fields = dom.div('#page-fields');
			var fp = new Spontaneous.FieldPreview(this, '');
			this._subviews.push(fp);
			var p = fp.panel();
			p.prepend(dom.div('.overlay'));

			var preview_area = this.create_edit_wrapper(p);
			fields.append(preview_area);
			this.panel.append(fields);
			var boxes = new Spontaneous.BoxContainer(this.page, 'page-slots');
			this._subviews.push(boxes);
			this.panel.append(boxes.panel());
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
			return this.page.depth();
		},
		unloadView: function() {
		}
	});

	return PageView;
}(jQuery, Spontaneous, document));
