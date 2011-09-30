// console.log("Loading TopBar...")

Spontaneous.EventSource = (function($, S) {
	var EventSource = new JS.Singleton({
		eventSource: function() {
			if (!this._eventSource) {
				this._eventSource = new window.EventSource(S.Ajax.request_url('/events', true));
			}
			return this._eventSource;
		},

		addEventListener: function(event, callback) {
			this.eventSource().addEventListener(event, callback);
		}
	});
	return EventSource;
})(jQuery, Spontaneous);
