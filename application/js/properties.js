Spontaneous.Properties = (function($, S) {
	return function() {
		return {
			_props_debug: false,
			_props_properties: function() {
				if (!this._props_property_store) { this._props_property_store = {}; }
				return this._props_property_store;
			},
			_props_listeners: function() {
				if (!this._props_listener_store) { this._props_listener_store = {}; }
				return this._props_listener_store;
			},
			_props_notify_changed: function(property_names) {
				for (var c = 0, cc = property_names.length; c < cc; c++) {
					var property_name = property_names[c], property_value = this._props_properties()[property_name];
					if (this._props_debug) { console.log("notify change", property_name, property_value) }
					var listeners = this._props_listeners_for(property_name);
					for (var i = 0, ii = listeners.length; i < ii; i++) {
						var l = listeners[i], listener = l.listener, callback = l.callback;
						if (typeof listener === 'function') {
							listener(property_value);
						} else {
							listener[callback].call(listener, property_value);
						}
					}
				}
			},
			_props_set_individual: function(property_name, value) {
				if (this._props_set_individual_wo_callbacks(property_name, value)) {
					this._props_notify_changed([ property_name ]);
				}
			},
			_props_set_individual_wo_callbacks: function(property_name, value) {
				if (this._props_debug) { console.log("setting ", property_name, value) }
				orig_value = this._props_properties()[property_name];
				this._props_properties()[property_name] = value;
				var changed = (value !== orig_value)
				return changed;
			},
			_props_set_multiple: function(values) {
				var changed_props = [], property_name;
				for (property_name in values) {
					if (values.hasOwnProperty(property_name)) {
						if (this._props_set_individual_wo_callbacks(property_name, values[property_name])) {
							changed_props.push(property_name);
						}
					}
				}
				this._props_notify_changed(changed_props);
			},
			_props_listeners_for: function(property_name) {
				return this._props_listeners()[property_name] || [];
			},
			get: function(property_name) {
				return this._props_properties()[property_name];
			},
			set: function() {
				if (arguments.length === 1 && typeof arguments[0] === "object") {
					this._props_set_multiple(arguments[0]);
				} else if (arguments.length ===2) {
					this._props_set_individual(arguments[0], arguments[1]);
				}
			},
			add_listener: function(property_name, listener, callback) {
				var current_listeners = this._props_listeners()[property_name] || [];
				current_listeners.push({'listener': listener, 'callback': callback});
				this._props_listeners()[property_name] = current_listeners;
			}
		};
	};
})(jQuery, Spontaneous);
