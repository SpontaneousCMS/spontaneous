// console.log('Loading Authentication...')

Spontaneous.Auth = (function($, S) {
	return {
		Key: {
			key: function(site) {
				return site + '_api_key';
			},
			save: function(site, key) {
				localStorage.setItem(this.key(site), key);
			},
			load: function(site) {
				return localStorage.getItem(this.key(site)) || this.loadAutoLogin();
			},
			loadAutoLogin: function() {
				if (!this._autoLoginKey) {
					console.warn('Using auto login key for user', "'"+S.auto_login+"'");
					this._autoLoginKey = S.user_key;
				}
				return this._autoLoginKey;
			},
			remove: function(site) {
				localStorage.removeItem(this.key(site));
				return false;
			}
		}
	};
}(jQuery, Spontaneous));

