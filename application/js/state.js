console.log("Loading State...")

Spontaneous.State = (function($, S) {
	var ajax = S.Ajax;

	var ContentState = new JS.Class({
		initialize: function(content) {
			this.content = content;
			this.state = this.load();
		},
		load: function() {
			var s = (localStorage.getItem(this.storage_key()) || '{}');
			try {
				return JSON.parse(s);
			} catch (e) { return {}; }
		},
		save: function() {
			localStorage.setItem(this.storage_key(), this.toString());
		},
		storage_key: function() {
			return 'content-state-'+this.content.id();
		},
		activate_box: function(box) {
			this.state.box = box.id();
		},
		active_box: function() {
			return this.state.box;
		},
		activate_slot: function(slot) {
			this.state.slot = slot.id();
		},
		active_slot: function() {
			return this.state.slot;
		},
		toString: function() {
			return JSON.stringify(this.state);
		}
	});
	var State = new JS.Singleton({
		get: function(content) {
			var s = new ContentState(content);
			return s;
		},
		activate_box: function(content, box) {
			var s = this.get(content);
			s.activate_box(box);
			s.save();
		},
		active_box: function(content) {
			var s = this.get(content);
			return s.active_box();
		},
		activate_slot: function(content, slot) {
			var s = this.get(content);
			s.activate_slot(slot);
			s.save();
		},
		active_slot: function(content) {
			var s = this.get(content);
			return s.active_slot();
		}
	});
	return State;
}(jQuery, Spontaneous));
