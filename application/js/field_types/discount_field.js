console.log('Loading DiscountField...')
Spontaneous.FieldTypes.DiscountField = (function($, S) {
	var dom = S.Dom;
	var TextCommand = new JS.Class({
		name: '',
		pre: '',
		post: '',

		extend: {
			get_state: function(input) {
				var start = input[0].selectionStart, end = input[0].selectionEnd, value = $(input).val(),
				before = value.substr(0, start), middle = value.substr(start, (end - start)), after = value.substr(end);
				return {
					start: start,
					end: end,
					before: before,
					middle: middle,
					selection: middle,
					after: after
				}
			}
		},

		initialize: function(input) {
			this.input = input;
		},
		execute: function() {
			this.wrap();
		},
		wrap: function() {
			var input = this.input, s = TextCommand.get_state(input), start = s.start, end = s.end,
				before = s.before, middle = s.middle, after = s.after, wrapped;
			if ((end - start) <= 0 ) { return; }
			if (this.matches_selection(middle)) {
				wrapped  = this.remove(middle)
			} else {
				wrapped = this.surround(middle);
			}
			input.val(before + wrapped + after);
			input[0].selectionStart = start;
			input[0].selectionEnd = start + wrapped.length;
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
				var b = $(dom.a, {'class':this.name.toLowerCase()}).click(function() {
					this.execute();
					return false;
				}.bind(this)).text(this.name);
				this._button = b;
			}
			return this._button;
		},
		respond_to_selection: function(state) {
			if (this.matches_selection(state.selection)) {
				console.log('matches', this.name)
				this.button().addClass('active');
			} else {
				this.button().removeClass('active');
			}
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
		post: '**'
	});

	var Italic = new JS.Class(TextCommand, {
		name: 'Italic',
		pre: '_',
		post: '_'
	});
	var Link = new JS.Class(TextCommand, {
		name: 'Link',
		link_matcher: /^\[([^\]]+)\]\(([^\)]+)\)$/,
		surround: function(text, url) {
			if (!url) {
				url =  "http://example.com/";
			}
			var entered_url = window.prompt("Enter URL", url);
			console.log(entered_url)
			if (entered_url === null) {
				// user hit 'Cancel'
				entered_url = url;
			}
			if (entered_url === '') {
				return text;
			} else {
				return '[' + text + '](' + entered_url + ')';
			}
		},
		remove: function(text) {
			// remove is mostly change
			var m = this.link_matcher.exec(text), text = m[1], url = m[2]
			return this.surround(text, url);
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

	var H1 = new JS.Class(TextCommand, {
		name: "H1",
		pre: '',
		post: "=",
		scale: 1.0,
		surround: function(text) {
			// remove existing header (which must be different from this version)
			if (this.matches_removal(text)) { text = this.remove(text); }
			var line = '', n = Math.max(text.length, 30), newline = /([\r\n]+)$/, newlines = newline.exec(text), undef;
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
			return (new RegExp('[\r\n]'+this.post+'+[\r\n ]*$')).exec(selection)
		}
	});

	var H2 = new JS.Class(H1, {
		name: "H2",
		post: "-",
		scale: 1.2 // hyphens are narrower than equals and narrower than the average char
	});

	var DiscountField = new JS.Class(Spontaneous.FieldTypes.StringField, {
		actions: [Bold, Italic, H1, H2, Link],
		get_input: function() {
			this.input = $(dom.textarea, {'id':this.css_id(), 'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
			return this.input;
		},
		edit: function() {
			this._wrapper = $(dom.div, {'class':'markdown-editor', 'id':'editor-'+this.css_id()});
			this._toolbar = $(dom.div, {'class':'md-toolbar'});
			this.input = $(dom.textarea, {'id':this.css_id(), 'name':this.form_name(), 'rows':10, 'cols':30}).text(this.unprocessed_value());
			this.input.select(this.on_select.bind(this))
			var c = this.actions;
		this.commands = [];
			for (var i = 0, ii = c.length; i < ii; i++) {
				var cmd_class = c[i], cmd = new cmd_class(this.input);
				this.commands.push(cmd);
				this._toolbar.append(cmd.button());
			}
			this._wrapper.append(this._toolbar).append(this.input)
			return this._wrapper;
		},
		// iterates through all the buttons and lets them highlight themselves depending on the
		// currently selected text
		on_select: function(event) {
			console.log(event)
			var state = TextCommand.get_state(this.input);
			$.each(this.commands, function() {
				this.respond_to_selection(state);
			});
		}
	});

	return DiscountField;
})(jQuery, Spontaneous);

