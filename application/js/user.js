// console.log('Loading User...')

Spontaneous.User = (function($, S) {
	var User = new JS.Class({
		initialize: function(user_data) {
			this.attrs = user_data;
		},
		name: function() {
			return this.attrs.name;
		},
		email: function() {
			return this.attrs.email;
		},
		login: function() {
			return this.attrs.login;
		},
		is_developer: function() {
			return this.attrs.developer;
		}
	});

	var instance = new JS.Singleton({
		include: Spontaneous.Properties,
		load: function() {
			S.Ajax.get('/user', this.loaded.bind(this));
		},
		loaded: function(user_data) {
			this.user = new User(user_data);
			this.set('user', this.user);
		},
		name: function() { return this.user.name(); },
		email: function() { return this.user.email(); },
		login: function() { return this.user.login(); },
		is_developer: function() { return this.user.is_developer(); }
	});
	return instance;
}(jQuery, Spontaneous));
