// console.log("Loading StatusBar...");


Spontaneous.StatusBar = (function($, S) {
	var dom = S.Dom;

	var StatusBar = {
		showing: false,
		init: function() {
			this.container = dom.div('#status-bar').hide();
			S.UploadManager.init(this);
			// window.setTimeout(function() {this.hide();}.bind(this), 1000);
			return this.container;
		},
		hide: function() {
			if (!this.showing) { return; }
			this.showing = false;
			var duration = 200;
			window.setTimeout(function() {
				// S.ContentArea.wrap.velocity({'bottom': 0}, duration);
				// S.Dialogue.overlay().velocity({'bottom': 0}, duration);
				this.container.velocity({'height': 0}, duration, function() { /* this.container.hide() */ }.bind(this));
			}.bind(this), 500);
		},
		show: function() {
			if (this.showing) { return; }
			this.showing = true;
			var duration = 200, height = 32;
			// S.ContentArea.wrap.velocity({'bottom': height}, duration);
			// S.Dialogue.overlay().velocity({'bottom': height}, duration);
			this.container.css('height', 0+'px');
			this.container.show();
			this.container.velocity({'height': height}, duration);
		},
		progress_container: function() {
			if (!this._progress_container) {
				var c = dom.div('#progress-container');
				this.container.append(c);
				this._progress_container = c;
			}
			return this._progress_container;
		}
	};
	return StatusBar;
})(jQuery, Spontaneous);


