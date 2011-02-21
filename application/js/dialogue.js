console.log('Loading Dialogue...')

Spontaneous.Dialogue = (function($, S) {
	var dom = S.Dom;


	var Button = new JS.Class({
		initialize: function(label, action, is_default) {
			this.label = label;
			this.action = action;
			this.is_default = is_default;
			this.disabled = false;
		},

		html: function() {
			var el = $(dom.a, {'class': this.css_class() }).text(this.label);
			if (typeof this.action === 'function') {
				var __button = this;
				el.click(function() {
					if (!__button.disabled) { __button.action(); }
					return false;
				});
			}
			this.button = el;
			return el;
		},
		css_class: function() {
			return ['button', (this.is_default ? 'default' : ''), this.label.toLowerCase().split(' ')[0]].join(' ');
		},
		disable: function() {
			this.set_disabled(true)
		},
		enable: function() {
			this.set_disabled(false)
		},
		set_disabled: function(state) {
			this.disabled = state;
			this.button.removeClass('disabled');
			if (this.disabled) {
				this.button.addClass('disabled')
			}
		}
	});
	var CancelButton = new JS.Class(Button, {
		initialize: function(label, is_default) {
			this.callSuper(label + " (Esc)", function() {
				Spontaneous.Dialogue.cancel();
			}, is_default);
		},
		css_class: function() {
			return this.callSuper().replace(' cancel', '') + ' cancel';
		}
	});
	var Dialogue = new JS.Class({
		open: function() {
			Spontaneous.Dialogue.open(this);
		},
		close: function() {
			Spontaneous.Dialogue.close(this);
		},
		buttons: function() {
			// return a
			//   { label : action }
			// or
			//   { label : [action, is_default ]}
			// set to define non-cancel action buttons
			// for this dialogue
		},
		cleanup: function() {
			// over-ride if you need to do anything before the dialogue is closed
			// (either by cancel or through other actions)
		},
		cancel_label: function() {
			return 'Cancel';
		},
		disable_button: function(button_name) {
			Spontaneous.Dialogue.disable_button(button_name);
		}
	});

	Dialogue.extend({
		_overlay: false,
		_open: false,
		_z_index: 1000,
		_instance: false,

		open: function(instance) {
			if (this._open) { return; }
			this._instance = instance;
			$('body').css("overflow", "hidden");
			this.overlay().fadeIn(200);
			var c = this.container(), a = this._actions, b;
			var buttons = instance.buttons(), button_map = {};
			a.empty();
			b = new CancelButton(instance.cancel_label());
			button_map['cancel'] = b;
			button_map[instance.cancel_label().toLowerCase()] = b;
			a.append(b.html());
			if (buttons) {
				$.each(buttons, function(label, params) {
					var action, is_default = false;
					if (typeof params === 'function') {
						action = params;
					} else if ($.isArray(params)) {
						action = params[0];
						is_default = params[1];
					} else {
						action = params.action;
						is_default = params.is_default;
					}
					b = new Button(label, action, is_default);
					a.append(b.html());
					button_map[label.toLowerCase()] = b;
				});
			}
			this.button_map = button_map;
			this._body.empty().append(instance.body());
			c.fadeIn(200);
			$(document).bind('keydown.dialogue', function(event) {
				if (event.keyCode === 27) { // escape key
					this.cancel();
				}
			}.bind(this));
			this._open = true;
		},

		disable_button: function(button_name) {
			var button = this.button_map[button_name.toLowerCase()]
			button.disable();
		},
		close: function() {
			if (!this._instance || !this._open) { return; }
			this._instance.cleanup();
			this.container().hide();
			this.overlay().fadeOut(200, function() {
				$('body').css("overflow", "auto");
			});
			this._instance = this._open = false;
			$(document).unbind('keydown.dialogue');
		},
		cancel: function() {
			return this.close();
		},
		container: function() {
			if (!this._container) {
				var w = $(dom.div, {'id':'dialogue-wrap'}).css('z-index', this.z_index()).hide();
				var cw = $(dom.div, {'id':'dialogue-control-wrap'});
				var c = $(dom.div, {'id':'dialogue-controls'});
				var a = $(dom.div, {'class':'dialogue-actions top'});
				var b = $(dom.div, {'id':'dialogue-body'});

				c.append(a);
				cw.append(c);
				w.append(cw);
				w.append(b);
				$('#content').append(w);
				this._actions = a;
				this._container = w;
				this._body = b;
			}
			return this._container;
		},
		overlay: function() {
			if (!this._overlay) {
				var o = $(dom.div, {'id':'dialogue-overlay'}).css('z-index', this.z_index()).hide();
				$('#content').append(o)
				this._overlay = o;
			}
			return this._overlay;
		},
		z_index: function() {
			return ++this._z_index;
		}
	});
	return Dialogue;
})(jQuery, Spontaneous);
