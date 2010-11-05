console.log("Loading StatusBar...");


Spontaneous.StatusBar = (function($, S) {
	var dom = S.Dom;

	var StatusBar = {
		init: function() {
			this.container = $(dom.div, {'id':'status-bar'});
			S.UploadManager.init(this);
			window.setTimeout(function() {this.hide();}.bind(this), 1000);
			return this.container;
		},
		hide: function() {
			var duration = 200;
			S.ContentArea.wrap.animate({'bottom': 0}, duration);
			this.container.animate({'height': 0}, duration);
		},
		show: function() {
			var duration = 200, height = 32;
			S.ContentArea.wrap.animate({'bottom': height}, duration);
			this.container.animate({'height': height}, duration);
		}
	};
	return StatusBar;
})(jQuery, Spontaneous);


