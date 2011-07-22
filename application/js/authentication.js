// console.log('Loading Authentication...')

Spontaneous.Auth = (function($, S) {
	var api_key_name = "spontaneous_api_key";
	return {
		Key: {
			save: function(key) {
				localStorage.setItem(api_key_name, key);
			},
			load: function() {
				return localStorage.getItem(api_key_name);
			},
			delete: function() {
				localStorage.removeItem(api_key_name);
				return false;
			}
		}
	};
}(jQuery, Spontaneous));

