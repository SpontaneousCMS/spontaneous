// console.log('Loading User...')

Spontaneous.User = (function($, S) {
	var ajax = S.Ajax;

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
		},
		can_publish: function() {
			return this.attrs.can_publish;
		}
	});

	var instance = new JS.Singleton({
		include: Spontaneous.Properties,

		loaded: function(user_data) {
			this.user = new User(user_data);
			this.set('user', this.user);
		},
		logout: function() {
			ajax.post("/logout", {}, function() {
				// S.Ajax.unauthorized();
			});
			S.Auth.Key.remove(S.site_id);
		},
		name: function() { return this.user.name(); },
		email: function() { return this.user.email(); },
		login: function() { return this.user.login(); },
		is_developer: function() { return this.user.is_developer(); },
		can_publish: function() { return this.user.can_publish(); }
	});
	return instance;
}(jQuery, Spontaneous));
