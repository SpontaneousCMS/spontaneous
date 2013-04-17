(function(S, $) {
	var dom = S.Dom;
	var sharedUserAdmin = new Spontaneous.MetaView.UserAdmin();
	var RootMenuView = new JS.Class(S.PopoverView, {
		initialize: function(afterCloseCallback) {
			this.afterCloseCallback = afterCloseCallback;
			this.callSuper();
		},
		width: function() {
			return 250;
		},
		title: function() {
			return "Main Menu";
		},
		position_from_event: function(event) {
			var pos = this.callSuper();
			return {left: pos.left - 12, top: pos.top + 1};
		},
		view: function() {
			var outer = dom.div("#root-menu")
			outer.append(this.serviceMenu(), this.userActionMenu());
			return outer;
		},
		after_close: function() {
			if (this.afterCloseCallback && (typeof this.afterCloseCallback === "function")) {
				this.afterCloseCallback();
			}
		},
		userActionMenu: function() {
			var menu = dom.ul(".user-actions");
			menu.append(dom.li('.user.title').text(S.User.name()));
			if (S.User.is_admin()) {
				var manage = dom.a().text("User Administration").click(function() {
					Spontaneous.ContentArea.enterMeta(sharedUserAdmin);
					Spontaneous.Popover.close();
				});
				menu.append(dom.li('.user-administration').append(manage));
			}
			var logout = dom.a().text("Logout").click(function() {
				console.log("Logout");
				S.User.logout();
			});
			menu.append(dom.li('.logout').append(logout));
			return menu;
		},
		serviceMenu: function() {
			var menu = dom.ul(".external-services");
			var self = this;
			var services = S.Services.serviceList();
			if (services.length > 0) {
				menu.append(dom.li(".title").text("Services"));
				services.forEach(function(service) {
					var link = dom.a().text(service.title).click(function() {
						self.close();
						S.Services.open(service);
					});
					menu.append(dom.li().append(link))
				});
			}
			return menu;
		}
	});
	S.RootMenuView = RootMenuView;

}(Spontaneous, jQuery));
