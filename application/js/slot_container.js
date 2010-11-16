console.log('Loading SlotContainer...')

Spontaneous.SlotContainer = (function($, S) {
	var dom = S.Dom;

	var SlotContainer = new JS.Class({

		initialize: function(content, wrap_id) {
			this.content = content;
			this.wrap_id = wrap_id;
			this.slot_content_container = $(dom.div);
		},

		panel: function() {
			var wrapper = $(dom.div, {'id':this.wrap_id, 'class':'slots'});

			wrapper.append(this.tab_bar());
			wrapper.append(this.slot_content_container);
			var s = Spontaneous.State.active_slot(this.content);
			this.activate_id(s);
			return wrapper;
		},
		tab_bar: function() {
			if (this.slots().length === 0) { return ''; }
			if (!this._tab_bar) {
				var bar = $(dom.ul, {'class':'slot-tabs'});
				for (var i = 0, slots = this.slots(), ii = slots.length; i < ii; i++) {
					var slot = slots[i];
					var li = $(dom.li)
					li.text(slot.name())
					li.append($(dom.span, {'class':'down'}));
					var click = function(index) {
						this.activate(index, true);
					}.bind(this, i);
					li.click(click);
					bar.append(li);
				}
				this._tab_bar = bar;
			}
			return this._tab_bar;
		},
		activate: function(slot_index, manually) {
			var slot = this.slots()[slot_index];
			if (slot === this._active_slot) { return; }
			$('li', this.tab_bar()).removeClass('active');
			$('li:nth-child('+(slot_index+1)+')', this.tab_bar()).addClass('active')
			slot.activate();
			this._active_slot = slot;
			if (manually) {
				Spontaneous.State.activate_slot(this.content, slot);
				this.content.set('slot', slot);
			}
		},
		activate_id: function(id) {
			if (id) {
				for (var i = 0, ss = this.slots(), ii = ss.length; i < ii; i++) {
					var s = ss[i];
					if (ss[i].id() === id) {
						this.activate(i);
						return;
					}
				}
			}
			// just in case
			this.activate(0);
		},
		slots: function() {
			if (!this._slots) {
				// console.log("SlotContainer#slots", this.content.entries);
				var _slots = [], content_container = this.slot_content_container;
				var f = function(i, slot) {
					_slots.push(new Spontaneous.Slot(slot.content, this.content, content_container))
				}.bind(this);
				$.each(this.content.entries(), f);
				this._slots = _slots;
			} 
			return this._slots;
		}
	});
	return SlotContainer;
})(jQuery, Spontaneous);

