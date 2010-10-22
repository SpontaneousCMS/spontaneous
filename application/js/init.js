console.log("Loading Init...");

Spontaneous.Init = (function($, S) {
	with (Spontaneous) {
		Location.add_listener('location', TopBar, 'location_changed');
		Location.add_listener('location', ContentArea, 'location_changed');

		// TopBar.add_listener('mode',       ContentArea, 'mode_changed');

		//
		// Preview.add_listener('location', Location, 'update');
		// Editing.add_listener('location', Location, 'update');
		// Location.add_listener('location',TopBar, 'location_changed');
		// // Location.add_listener('map',     TopBar, 'map_changed');
		// TopBar.add_listener('location',  ContentArea, 'goto');
		// TopBar.add_listener('mode',      ContentArea, 'display');
		// Editing.add_listener('location', SideBar, 'location_changed');
		// Preview.add_listener('location', SideBar, 'location_changed');

		return function() {
			Types.init();
			Location.init();
			Dom.body().append(SideBar.panel());
			Dom.body().append(TopBar.panel());
			Dom.body().append(ContentArea.init());
			
			Spontaneous.Spin = SideBar.spinner();
			// TopBar.init();
		};
	}
})(jQuery, Spontaneous);

