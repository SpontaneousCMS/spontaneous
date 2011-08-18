// console.log('Loading Authentication...')

Spontaneous.Auth = (function($, S) {
	return {
		Key: {
			key: function(site) {
				return site + '_api_key'
			},
			save: function(site, key) {
				localStorage.setItem(this.key(site), key);
			},
			load: function(site) {
				return localStorage.getItem(this.key(site));
			},
			remove: function(site) {
				localStorage.removeItem(this.key(site));
				return false;
			}
		}
	};
}(jQuery, Spontaneous));

