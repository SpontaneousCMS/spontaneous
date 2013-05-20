// console.log('Loading Metadata...')

Spontaneous.Metadata = (function($, S) {
	var ajax = S.Ajax;
	var loaded = function(callback) {
		return function(metadata) {
			S.Types.loaded(metadata.types);
			S.User.loaded(metadata.user);
			S.Services.loaded(metadata.services);
			if (callback) { callback(metadata); };
		};
	};
	return {
		load: function(onComplete) {
			ajax.get('/site', loaded(onComplete));
		}
	};
}(jQuery, Spontaneous));


