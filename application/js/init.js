// console.log("Loading Init...");


Spontaneous.Init = (function($, S) {

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

		var location = S.Location, top_bar = S.TopBar, content_area = S.ContentArea, b = S.Dom.body();
		//// won't work unfortunately
		// $('img').live('error', function() {
		// 	console.log('error', this)
		// 	$(this).attr('src', '/media/01158/0039/fright_night.jpeg')
// });

		location.add_listener('location', top_bar, 'location_changed');
		location.add_listener('location', content_area, 'location_changed');

		top_bar.add_listener('mode',       content_area, 'display');
		top_bar.add_listener('mode',       location, 'view_mode_changed');

		S.Editing.add_listener('page', location, 'page_loaded');

		b.append(top_bar.panel());
		b.append(content_area.init());
		b.append(S.StatusBar.init());

		S.Types.init(function() {
		location.init(function() {
			top_bar.init();
		});
	});




		// $(document).click(function(event) {
		// 	Spontaneous.Popover.open(event, new Spontaneous.PopoverView())
		// })
		// Spontaneous.Spin = SideBar.spinner();
	};
})(jQuery, Spontaneous);

