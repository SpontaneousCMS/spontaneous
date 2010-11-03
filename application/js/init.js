console.log("Loading Init...");

var __init_loaded = false;

Spontaneous.Init = (function($, S) {
	with (Spontaneous) {
		Location.add_listener('location', TopBar, 'location_changed');
		Location.add_listener('location', ContentArea, 'location_changed');

		TopBar.add_listener('mode',       ContentArea, 'display');

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
			if (__init_loaded) { return; }
			console.log('Spontaneous.Init', __init_loaded);
			Types.init();
			Location.init(function() {
				Dom.body().append(TopBar.panel());
				Dom.body().append(ContentArea.init());
			});
			
			// Spontaneous.Spin = SideBar.spinner();
			TopBar.init();
			__init_loaded = true;
		};
	}
})(jQuery, Spontaneous);

