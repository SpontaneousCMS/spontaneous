Spontaneous.Properties = (function($, S) {
	var Properties = new JS.Module({
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
				// if (this._props_debug) { console.log("Properties: notify change:", property_name, property_value) }
				var listeners = this._props_listeners_for(property_name);
				// if (this._props_debug) { console.log("Properties: notify change", listeners) }
				for (var i = 0, ii = listeners.length; i < ii; i++) {
					var callback = listeners[i].callback;
					callback(property_value);
				}
			}
		},
		_props_set_individual: function(property_name, value) {
			if (this._props_set_individual_wo_callbacks(property_name, value)) {
				this._props_notify_changed([property_name]);
			}
		},
		_props_set_individual_wo_callbacks: function(property_name, value) {
			if (this._props_debug) { console.log('setting ', property_name, value); }
			orig_value = this._props_properties()[property_name];
			this._props_properties()[property_name] = value;
			var changed = (value !== orig_value);
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
		_props_add_listener: function(name, callback) {
			var current_listeners = this._props_listeners()[name] || [];
			// console.log('current_listeners', name, current_listeners.length)
			current_listeners.push({'callback': callback});
			this._props_listeners()[name] = current_listeners;
		},
		_props_remove_listener: function(name, callback) {
			var current_listeners = this._props_listeners()[name] || [], listeners = [];
			for (var i = 0, ii = current_listeners.length; i < ii; i++) {
				var l = current_listeners[i];
				if (l.callback !== callback) {
					listeners.push(l);
				}
			}
			this._props_listeners()[name] = listeners;
		},
		// get the value of a property
		get: function(property_name) {
			return this._props_properties()[property_name];
		},
		// set the value of a property. can be called as
		//   set('property_name', property_value)
		// or as
		//   set({'property_name_1': property_value_1, 'property_name_2':property_value_2})
		// all watchers of this property will be notified of the change
		// (only if the value acutally changes)
		set: function() {
			if (arguments.length === 1 && typeof arguments[0] === 'object') {
				this._props_set_multiple(arguments[0]);
			} else if (arguments.length ===2) {
				this._props_set_individual(arguments[0], arguments[1]);
			}
		},
		// assign a callback function to a property to be called when that property changes
		watch: function(property_name, callback) {
			return this._props_add_listener(property_name, callback);
		},
		unwatch: function(property_name, callback) {
			return this._props_remove_listener(property_name, callback);
		},
		// assign a callback to an event to be called when that event is triggered
		bind: function(event_name, callback) {
			return this._props_add_listener(event_name, callback);
		},
		// trigger a particular event
		trigger: function() {
			var args = Array.prototype.slice.call(arguments);
			var event_name = args.shift(), listeners = this._props_listeners_for(event_name);
			for (var i = 0, ii = listeners.length; i < ii; i++) {
				listeners[i].callback.apply(null, args);
			}
		},
		// set a listener on the 'property_name' property of the object `target`
		// and remember it so we can remove it later (using 'unwatchOthers')
		watchOther: function(target, property_name, callback) {
			var others = this._props_watching || [];
			others.push({target: target, property_name: property_name, callback: callback});
			this._props_watching = others;
			return target.watch(property_name, callback);
		},
		unwatchOthers: function() {
			var others = this._props_watching || [];
			for (var i = 0, ii = others.length; i < ii; i++) {
				var watcher = others[i];
				watcher.target.unwatch(watcher.property_name, watcher.callback);
			}
		}
	});
	return Properties;
}(jQuery, Spontaneous));
