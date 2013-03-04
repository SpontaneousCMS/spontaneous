// console.log('Loading DiscountField...')

Spontaneous.Field.Markdown = (function($, S) {
	var dom = S.Dom;
	var TextCommand = new JS.Class({
		name: '',
		pre: '',
		post: '',

		extend: {
			get_state: function(input) {
				var start = input[0].selectionStart, end = input[0].selectionEnd, value = input.val(),
				before = value.substr(0, start), middle = value.substr(start, (end - start)), after = value.substr(end), state;
				state = {
					start: start,
					end: end,
					before: before,
					middle: middle,
					selection: middle,
					after: after
				};
				// console.log(state)
				return state;
			}
		},

		initialize: function(input) {
			this.input = input.bind('keydown.markdown', function(event) {
				var key = String.fromCharCode(event.keyCode)
				if ((event.ctrlKey || event.metaKey) && key === this.key_shortcut()) {
					this.execute(event);
					return false;
				}
			}.bind(this));
		},
		key_shortcut: function() {
			return "";
		},
		execute: function(event) {
			this.wrap();
		},
		wrap: function() {
			var input = this.input, s = this.fix_selection(), start = s.start, end = s.end,
				before = s.before, middle = s.selection, after = s.after, wrapped;
			// if ((end - start) <= 0 ) { return; }
			if (this.matches_selection(middle)) {
				wrapped  = this.remove(middle)
			} else {
				wrapped = this.surround(middle);
			}
			input.val(before + wrapped + after);
			input[0].selectionStart = start;
			input[0].selectionEnd = start + wrapped.length;
		},
		get_state: function() {
			return TextCommand.get_state(this.input);
		},
		fix_selection_whitespace: function(state) {
			var selected = state.selection, m, l;
			m = /^( +)/.exec(selected);
			if (m) {
				l = m[1].length
				state.start += l;
				state.selection = selected.substr(l);
			}
			m = /( +)$/.exec(selected);
			if (m) {
				l = m[1].length
				state.end -= l;
				state.selection = selected.substr(0, selected.length-l);
			}
			return state;
		},
		expand_selection: function(state) {
			state = this.fix_selection_whitespace(state);
			var selected = state.selection, m, start = state.start, end = state.end,
				_pre_ = this.pre.replace(/\*/g, "\\*"), _post_ = this.post.replace(/\*/g, "\\*");

			m = (new RegExp('(?:^| )('+_pre_+'[^('+_pre_+')]*)$', 'm')).exec(state.before)
			if (m) {
				start -= m[1].length;
				selected = m[1] + selected;
			}
			m = (new RegExp('^([^('+_post_+')]*?'+_post_+')[^('+_post_+')\w ]*?( |$)', '')).exec(state.after)
			if (m) {
				end += m[1].length;
				selected += m[1];
			}
			// fix condition where half of the pre/post markers are selected
			if ((end - start) > 0) {
				if (selected.indexOf(this.pre) !== 0) {
					var sel;
					for (var i = 0, ii = this.pre.length; i < ii; i++) {
						sel = state.before.substr(-(i+1)) + selected;
						if (sel.indexOf(this.pre) === 0) {
							start -= (i+1);
							selected = sel;
							break;
						}
					}
				}
				if (selected.substr(-this.post.length) !== this.post) {
					var sel;
					for (var i = 0, ii = this.post.length; i < ii; i++) {
						sel = selected + state.after.substr(0, (i+1));
						if (sel.substr(-this.post.length) === this.post) {
							end += (i+1);
							selected = sel;
							break;
						}
					}
				}
			} else {
				// expand selection to current word if selection is empty
				var exclude = '\\s\\b\\.,';
				m = (new RegExp('(?:['+exclude+']|^)([^'+exclude+']+)$', '')).exec(state.before)
				if (m) {
					start -= m[1].length;
					selected = m[1] + selected;
				}
				m = (new RegExp('^([^'+exclude+']*)(?:['+exclude+']|$)', '')).exec(state.after);
				if (m) {
					end += m[1].length;
					selected += m[1];
				}
			}
			return {start: start, end: end, selection:selected};
		},
		fix_selection: function() {
			var state = this.get_state(), change;
			if (!this.matches_selection(state.selection)) {
				change = this.expand_selection(state)
				$.extend(state, change);
				state = this.update_state(state);
			}
			return state;
		},
		update_state: function(state) {
			this.input[0].setSelectionRange(state.start, state.end);
			return this.get_state();
		},
		surround: function(text) {
			return this.pre + text + this.post;
		},
		remove: function(text) {
			return text.substr(this.pre.length, text.length - this.pre.length - this.post.length);
		},
		value: function() {
			return this.input.val();
		},
		button: function() {
			if (!this._button) {
				// var b = $(dom.a, {'class':this.name.toLowerCase()}).click(function(event) {
				var b = dom.a(this.name.toLowerCase()).click(function(event) {
					this.execute(event);
					return false;
				}.bind(this)).text(this.name);
				this._button = b;
			}
			return this._button;
		},
		respond_to_selection: function(state) {
			this.deactivate();
			if (this.matches_selection(state.selection) || this.matches_selection(this.expand_selection(state).selection)) {
				this.activate();
				return true;
			} else {
				this.deactivate();
				return false;
			}
		},
		activate: function() {
			this.button().addClass('active');
		},
		deactivate: function() {
			this.button().removeClass('active');
		},
		matches_removal: function(selection) {
			return this.matches_selection(selection);
		},
		matches_selection: function(selection) {
			return (selection.indexOf(this.pre) === 0 && selection.lastIndexOf(this.post) === (selection.length - this.post.length))
		}
	});

	var Bold = new JS.Class(TextCommand, {
		name: 'Bold',
		pre: '**',
		post: '**',
		key_shortcut: function() {
			return "B"; // "b"
		},
	});

	var Italic = new JS.Class(TextCommand, {
		name: 'Italic',
		pre: '_',
		post: '_',
		key_shortcut: function() {
			return "I";
		},
	});

	var UL = new JS.Class(TextCommand, {
		name: 'UL',
		pre: '*',
		post: '',
		br: /\r?\n/,
		strip_bullet: /^ *(\d+\.|\*) */,
		is_list_entry:/(?:\r?\n)( *\*{1} +.+?)$/,
		surround: function(text) {
			var lines = text.split(this.br);
			for (var i = 0, ii = lines.length; i < ii; i++) {
				if (/^\s*$/.test(lines[i])) {
				} else {
					lines[i] = this.bullet_for(i) + lines[i].replace(this.strip_bullet, '');
				}
			}
			return lines.join("\n")
		},
		remove: function(text) {
			var lines = text.split(this.br);
			for (var i = 0, ii = lines.length; i < ii; i++) {
				lines[i] = lines[i].replace(this.strip_bullet, '');
			}
			return lines.join("\n")
		},
		expand_selection: function(state) {
			var selected = (state.selection || ''), m, start = state.start, end = state.end, br = /\r?\n/;
			m = this.strip_bullet.exec(selected);
			if (!m) {
				m = this.is_list_entry.exec(state.before);
				if (m) {
					start -= m[1].length;
					selected = m[1] + selected;
					m = /^(.*?)(?:\r?\n)/.exec(state.after);
					if (m) {
						end += m[1].length;
						selected += m[1];
					}
				}
			}
			return {selection:selected, start:start, end:end};
		},
		bullet_for: function(n) {
			return "* ";
		},
		matches_selection: function(selection) {
			return /^ *\* +/.test(selection)
		}

	});
	var OL = new JS.Class(UL, {
		name: 'OL',
		is_list_entry:/(?:\r?\n)( *\d+\..+?)$/,
		bullet_for: function(n) {
			return (n+1)+". ";
		},
		matches_selection: function(selection) {
			return /^ *\d+\./.test(selection)
		}
	});

	var H1 = new JS.Class(TextCommand, {
		name: "H1",
		pre: '',
		post: "=",
		scale: 1.0,
		key_shortcut: function() {
			return "1";
		},
		surround: function(text) {
			// remove existing header (which must be different from this version)
			if (this.matches_removal(text)) { text = this.remove(text); }
			var line = '', n = Math.floor(this.input.attr('cols')*0.5), newline = /([\r\n]+)$/, newlines = newline.exec(text), undef;
			newlines = (!newlines || (newlines === undef) ? "" : newlines[1])
			for (var i = 0; i < n; i++) { line += this.post; }
			return text.replace(newline, '') + "\n" + line + newlines;
		},
		// removes either h1 or h2
		remove: function(text) {
			var r = new RegExp('[\r\n][=-]+'), s =  text.replace(r, '')
			return s.replace(/ +$/, '');
		},
		// matches either h1 or h2
		matches_removal: function(selection) {
			return (new RegExp('[\r\n][=\\-]+[\r\n ]*$')).exec(selection)
		},
		// matches only the current header class
		matches_selection: function(selection) {
			return (new RegExp('[\r\n]?'+this.post+'+[\r\n ]*$', 'm')).exec(selection)
		},
		expand_selection: function(state) {
			var selected = (state.selection || ''), m, start = state.start, end = state.end, br = /\r?\n/, below = false;
			// detect & deal with the cursor being on the line below
			// (the one with the -'s or ='s)
			// TODO: deal with the case where the cursor is at the start of the =- line
			m = /[\r\n]([=-]+)$/.exec(state.before);
			n = /^([=-]+)[\r\n]/.exec(state.after);
			if (m || n) {
				m = /(?:[\n]|^)(.+[\n]+([=-]+))$/.exec(state.before);
				if (m) {
					var s = m[1];
					start -= s.length;
					selected = s + selected;
				}
				if (n) {
					var s = n[1];
					end += s.length;
					selected += s;
				}
				below = true;
			}
			// if we're on the line below then skip all this
			if (!below) {
				// expand to select current line
				m = /(.+)$/.exec(state.before);
				if (m) {
					var s = m[1];
					start -= s.length;
					selected = m[1] + selected;
				}
				m = /^(.+)/.exec(state.after);
				if (m) {
					var s = m[1];
					end += s.length;
					selected += m[1];
				}
				var lines = selected.split(br), underline = new RegExp('^[=-]+$'), found = false;
				for (var i = 0, ii = lines.length; i < ii; i++) {
					var l = lines[i];
					if (underline.test(l)) {
						found = true;
						break;
					}
				}
				if (!found) {
					// expand selection down by one line
					lines = state.after.split(br, 2);
					for (var i = 0, ii = lines.length; i < ii; i++) {
						var l = lines[i];
						if (underline.test(l)) {
							end += l.length + i;
							selected += l;
							break;
						}
					}
				} else {
					// make sure that we have the whole of the underline included in the selection
					var r = new RegExp('^([=-]+)'), m = r.exec(state.after);
					if (m) {
						var extra = m[1];
						end += extra.length;
						selected += m[1];
					}
				}
			}
			return {selection:selected, start:start, end:end};
		}
	});

	var H2 = new JS.Class(H1, {
		name: "H2",
		post: "-",
		scale: 1.2, // hyphens are narrower than equals and narrower than the average char
		key_shortcut: function() {
			return "2";
		},
	});


	var LinkView = new JS.Class(Spontaneous.PopoverView, {
		initialize: function(editor, link_text, url) {
			this.editor = editor;
			this.link_text = link_text;
			this.url = url;
			this.callSuper();
		},
		width: function() {
			return 300;
		},
		title: function() {
			return "Insert Link";
		},
		// position_from_event: function(event) {
		// 	var t = $(event.currentTarget), o = t.offset();
		// 	o.top += t.outerHeight();
		// 	o.left += t.outerWidth() / 2;
		// 	return o
		// },
		close_text: function() {
			return 'Cancel';
		},
		// align: 'right',
		view: function() {
			var __view = this, w = dom.div('.pop-insert-link'), text_input, url_input;
			var input = function(label, value, type) {
				var l, i = dom[(type || 'input')]({'type':'text'}).keypress(function(event) {
					if (event.charCode === 13) {
						__view.insert_link_and_close(text_input, url_input); // sick
						return false;
					}
				}).val(value);
				l = dom.label().append(dom.span().text(label)).append(i);
				return l;
			}
			text_input = input("Text", this.link_text);
			url_input = input("URL", this.url, 'textarea');
			url_input.find('textarea').attr('rows', 3);

			cancel = dom.a('.button.cancel').text('Clear').click(function() {
				// this.close();
				this.insert_link_and_close(text_input, url_input.val(''));
				return false;
			}.bind(this)), insert = dom.a('.button').text('OK').click(function() {
				this.insert_link_and_close(text_input, url_input);
				return false;
			}.bind(this))
			w.append(dom.p().append(text_input)).append(dom.p().append(url_input));
			var buttons = dom.div('.buttons');
			url_input = url_input.find(':input')
			text_input = text_input.find(':input')
			this.text_input = text_input;
			this.url_input = url_input;
			this.page_browser = new PageSelector(this.url, this);
			w.append(this.page_browser.view());
			w.append(buttons.append(cancel).append(insert));
			this.wrapper = w;
			return w;
		},

		insert_link: function(text, url) {
			this.editor.insert_link(text.val(), url.val());
		},
		insert_link_and_close: function(text, url) {
			this.insert_link(text, url);
			this.close();
		},
		cancel: function() {
			this.close();
		},
		after_open: function() {
			this.wrapper.find('textarea').select();
		},
		after_close: function() {
			this.editor.dialogue_closed();
		},
		page_selected: function(page) {
			this.url_input.val(page.path);
		}
	});

	var PageSelector = new JS.Class({
		initialize: function(location, parent) {
			this.parent = parent;
			this.location = location
			this.browser = new Spontaneous.PageBrowser(this.location);
			this.browser.set_manager(this);
		},
		view: function() {
			var w = dom.div();
			text = dom.span().text('Page Browser'),
			inner = dom.div('.link-page-browser');
			inner.append(dom.label().append(text)).append(this.browser.view());
			w.append(inner);
			return w;
		},
		page_list_loaded: function(view) {
		},
		page_selected: function(page) {
			this.parent.page_selected(page);
		},
		next_level: function(page) {
			this.location = page
		}
	});

	var Link = new JS.Class(TextCommand, {
		name: 'Link',
		link_matcher: /^\[([^\]]+)\]\(([^\)]+)\)$/,
		execute: function(event) {
			var input = this.input, s = this.fix_selection(), start = s.start, end = s.end,
			before = s.before, middle = s.middle, after = s.after, wrapped,
			m = this.link_matcher.exec(middle), text = middle, url;
			if (m) {
				text = m[1];
				url = m[2];
			}
			this.open_dialogue(event, text, url);
			this.input.focus();
			return false;
		},
		open_dialogue: function(event, text, url) {
			if (!this._dialogue) {
				this._dialogue = Spontaneous.Popover.open(event, new LinkView(this, text, this.preprocess_url(text, url)));
			} else {
				this._dialogue.close();
				this._dialogue = null;
			}
		},
		expand_selection: function(state) {
			state = this.fix_selection_whitespace(state)
			var selected = state.selection, m, n, start = state.start, end = state.end;

			var linkExp = /(\[[^\]]*?\]\([^\ ]*?\))/g;
			var text = this.input.val(), cursor = start, match = 0;
			// First look at all the text before and move the cursor past any links.
			// This stops us expanding backwards to grab any link found in the text before
			// the selection start.
			do {
				if ((m = linkExp.exec(state.before))) { match = linkExp.lastIndex; }
			} while (m && (linkExp.lastIndex < cursor));

			// now we've established where the last whole link lives, and can stop ourselves
			// including it in the search, we can look backwards
			// until we find the start of any link that's around the current selection.
			while ((cursor >= match) && (text[cursor] !== "[")) { cursor--; }

			if (text[cursor] === "[") {
				if (m = linkExp.exec(text.substr(cursor))) {
					start = cursor;
					end = cursor + m[1].length;
					selected = m[1];
				}
			}
			return {selection:selected, start:start, end:end};
		},
		preprocess_url: function(text, url) {
			if (!url) {
				url = this.postprocess_url(String(text)) || '';
			}
			return url;
		},
		postprocess_url: function(url) {
			if (url) {
				if (/^(https?|mailto|ftp|javscript):/.test(url)) { // URLs staring with a protocol
					url = url;
				} else if (/^[a-z-]+\.([a-z-]+\.)*[a-z]{2,}(\/[^ ]*)*$/i.exec(url)) { // look for addresses without http:
					url = 'http://' + url;
				} else if (/^[^ @]+@([a-z-]+\.)+[a-z]{2,}$/i.exec(url)) { // email addresses
					url = 'mailto:' + url;
				} else if (/^@([a-z0-9_]{1,15})$/i.exec(url)) { // twitter handles
					url = 'https://twitter.com/' + url.substring(1);
				} else {
					// need a flag saying that the string doesn't look like URL because
					// this function is used in two places and each one needs to respond
					// differently to this condition
					return false
				}
			}
			return url;
		},
		dialogue_closed: function() {
			this._dialogue = null;
			this.input.focus();
		},
		insert_link: function(text, url) {
			url = this.postprocess_url(url) || url;
			var edit = function(input_text) {
				return this.surround_with_link(text, url);
			}.bind(this);
			this.surround = edit;
			this.remove = edit;
			this.wrap();
		},
		surround_with_link: function(text, url) {
			if (url === '') {
				return text;
			} else {
				return '[' + text + '](' + url + ')';
			}
		},
		remove_link: function(text) {
			// we know that the text must match the regexp for us to arrive here
			var m = this.link_matcher.exec(text);
			return m[1];
		},
		matches_selection: function(selection) {
			return this.link_matcher.exec(selection);
		}
	});


	var MarkdownField = new JS.Class(Spontaneous.Field.String, {
		actions: [Bold, Italic, H1, H2, UL, OL, Link],
		generate_input: function() {
			var input = dom.textarea(dom.id(this.css_id()), {'name':this.form_name(), 'rows':10, 'cols':90}).val(this.unprocessed_value()), height = this.content.getFieldMetadata(this, 'height');
			if (height) {
				input.css('height', dom.px(height));
			}

			return input;
		},
		on_show: function() {
			var self = this, input = self.input();
			input.resizable({
				handles: 's',
				minHeight: 100,
				stop: function(event, ui) {
					self.content.setFieldMetadata(self, 'height', ui.size.height);
				}
			});
		},
		on_focus: function() {
			if (!this.expanded) {
				var input = this.input(), h = input.innerHeight();

				input.data('original-height', h)
				var text_height = input[0].scrollHeight, max_height = 500, resize_height = Math.min(text_height, max_height);
				// console.log(resize_height, h)
				if (Math.abs(resize_height - h) > 20) {
					// input.animate({'height':resize_height});
					this.expanded = true;
				}
			}
			this.callSuper();
		},
		on_blur: function() {
			if (this.expanded) {
				var input = this.input();
				// input.animate({ 'height':input.data('original-height') });
				this.expanded = false;
			}
			this.callSuper();
		},
		toolbar: function() {
			var self = this;
			if (!self._toolbar) {
				self._wrapper = dom.div([dom.id('editor-'+self.css_id()), '.markdown-editor']);
				self._wrapper.append(self.popupToolbar());
			}
			return self._wrapper;
		},
		popupToolbar: function() {
			var self = this;
			if (!self._popupToolbar) {
				var toolbar = dom.div('.md-toolbar');
				var arrow = dom.div(".arrow");
				toolbar.append(arrow);
				self.commands = [];
				var input = self.input();
				for (var i = 0, c = self.actions, ii = c.length; i < ii; i++) {
					var cmd_class = c[i], cmd = new cmd_class(input);
					self.commands.push(cmd);
					toolbar.append(cmd.button());
				}
				toolbar.hide();
				self._popupToolbar = toolbar;
			}
			return self._popupToolbar;
		},
		edit: function() {
			var self = this, input = self.input();
			self.expanded = false;
			// clear previously assigned bindings
			input.unbind('select.markdown');
			input.bind('select.markdown', self.on_select.bind(self))
			// input.bind('click.markdown', self.on_select.bind(self))
			// input.bind('keyup.markdown', self.on_select.bind(self))
			return input;
		},
		close_edit: function() {
			var self = this;
			self._input = null;
			self._toolbar = null;
			self._popupToolbar = null;
			self.commands = [];
			self.expanded = false;
			self.callSuper();
		},
		// iterates through all the buttons and lets them highlight themselves depending on the
		// currently selected text
		on_select: function(event) {
			var input = this.input(), toolbar = this.popupToolbar(), state = TextCommand.get_state(input);
			$.each(this.commands, function() {
				this.respond_to_selection(state);
			});
			input.showSelectionPopup(toolbar, function(position) {
				var tools = {width: toolbar.width(), height: toolbar.height()},
				text = { width: input.width(), height: input.height()};
				// console.log("position", position, tools, text);
				var place = {
					left: position.left,
				  // 5 is half the height of the arrow
				  // 7 is the padding of the field
					top: position.top + 7 - 5  - tools.height
				};
				var dx = 0;
				var arrow = toolbar.find(".arrow"),
				arrowLeft = (position.width / 2) - 5;
				// if the selection is narrow the arrow can peek over the left
				// of the toolbar. This shifts everything over and keeps it neat.
				if (position.width < 40) {
					place.left = place.left - 15;
					arrowLeft += 15;
				}
				if ((place.left + tools.width) > (text.width)) {
					dx = ((place.left + tools.width) - (text.width + 20));
					place.left = place.left - dx;
					arrowLeft += dx;
				}

				arrow.css("left", dom.px(arrowLeft));
				return place;
			});
		}
	});

	MarkdownField.extend({
		TextCommand: TextCommand,
		Bold: Bold,
		Italic: Italic,
		UL: UL,
		OL: OL,
		H1: H1,
		H2: H2,
		Link: Link
	});

	return MarkdownField;
})(jQuery, Spontaneous);

