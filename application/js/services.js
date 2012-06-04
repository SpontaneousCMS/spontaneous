// console.log('Loading Metadata...')

Spontaneous.Services = (function($, S) {
	var dom = S.Dom;
	var instance = new JS.Singleton({
		include: S.Properties,
		loaded: function(serviceData) {
			this.set('services', serviceData);
		},
		serviceList: function() {
			return this.get("services");
		},
		open: function(service) {
			S.TopBar.showService(service);
			S.ContentArea.showService(service);
		},
		close: function() {
			S.TopBar.showNavigationView();
			S.ContentArea.hideService();
		},
		init: function(container) {
			this.iframe = dom.iframe("#services_pane", {'src':'about:blank'})
			this.iframe.hide();
			container.append(this.iframe);
			return this;
		},
		display: function(url) {
			var iframe = this.iframe;
			iframe.fadeIn(200);
			// iframe.bind('ready.services', function() {
			// 	iframe.fadeIn(200);
			// });
			iframe[0].contentWindow.location.href = url;
		},
		hide: function() {
			this.iframe.unbind('ready.services').hide();
		},
		show: function() {
			this.iframe.show();
		}
	});
	return instance;
}(jQuery, Spontaneous));
