// console.log("Loading Init...");


Spontaneous.Init = (function($, S) {

	return function() {

		var location = S.Location, top_bar = S.TopBar, content_area = S.ContentArea, b = S.Dom.body();

		location.watch('location', top_bar.location_changed.bind(top_bar));
		location.watch('location', content_area.location_changed.bind(content_area));

		top_bar.watch('mode',       content_area.display.bind(content_area));
		top_bar.watch('mode',       location.view_mode_changed.bind(location));

		S.Editing.watch('page', location.page_loaded.bind(location));
		S.Editing.watch('path', location.path_changed.bind(location));

		b.append(top_bar.panel());
		b.append(content_area.init());
		b.append(S.StatusBar.init());

		S.Metadata.load(function(metadata) {
			location.init(function() {
				top_bar.init(metadata);
			});
		});
	};
}(jQuery, Spontaneous));
