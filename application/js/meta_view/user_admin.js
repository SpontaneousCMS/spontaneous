Spontaneous.MetaView.UserAdmin = (function($, S){
	var dom = S.Dom, ajax = S.Ajax;

	var Level = new JS.Class({
		initialize: function(attributes) {
			this.attributes = attributes;
		},
		levelName: function() { return this.attributes.level; },
		title: function() {
		 var level = this.attributes.level;
		 return level.charAt(0).toUpperCase() + level.substr(1);
		},
		canPublish: function() {
			return this.attributes.can_publish;
		},
		isAdmin: function() {
			return this.attributes.is_admin;
		}
	});

	Level.get = function(level) {
		return this.levels.filter(function(l) {
			return l.levelName() === level;
		})[0];
	};
	Level.defaultLevel = function() {
		var levels = this.levels;
		var nonePosition = function() {
			for (var i = 0, ii = levels.length; i < ii; i++) {
				if (levels[i].levelName() === "none") {
					return i;
				}
			};
		}();
		return levels[nonePosition + 1];
	};

	var LevelSelect = new JS.Class({
		initialize: function(name, user) {
			this.name = name;
			this.user = user;
		},
		element: function(cancelCallback) {
			var self = this;
			var levels = Level.levels;
			var currentLevel = Level.get(this.user.get("level")) || Level.defaultLevel();
			var outer = dom.div(".level-select");
			var input = dom.input({type: "hidden", name: Input.inputName(this.name), value: currentLevel.levelName()});
			var select = dom.div(".select").hide();
			var value = dom.div(".level-value").text(currentLevel.title());
			levels.forEach(function(level) {
				var row = dom.div(".level").addClass("level-" + level.levelName());
				row.append(dom.span(".level-name").text(level.title()));
				row.append(dom.span(".level-publish").text("Publish").addClass(""+level.canPublish()));
				row.append(dom.span(".level-admin").text("Admin").addClass(""+level.isAdmin()));
				row.data("level", level);
				row.click(function() {
					self.choose(level);
					return false;
				});
				select.append(row);
			});
			value.click(function() {
				self.open();
				return false;
			});
			outer.append(select, input, value);
			this.input = input;
			this.pulldown = select;
			this.level = currentLevel;
			this.value = value;
			return outer;
		},
		open: function() {
			var pulldown = this.pulldown;
			pulldown.fadeIn(100);
			var level = this.currentLevel();
			var options = pulldown.find(".level");
			var levelDiv = options.filter(function(div) {
				return $(this).data("level").levelName() == level.levelName();
			})[0];
			var pos = $(levelDiv).position();
			pulldown.css("top", dom.px(-pos.top));
		},

		choose: function(level) {
			this.input.val(level.levelName());
			this.value.text(level.title());

			this.close();
		},
		close: function( ) {
			this.pulldown.fadeOut(100);
		},
		activate: function() {
			this.select();
		},
		currentLevel: function() {
			return Level.get(this.input.val());
		},
		select: function() {
			var level = this.currentLevel();
			this.value.text(level.title());

		},
		showError: function(errors) { },
		hideError: function() { }
	});

	var Input = new JS.Class({
		initialize: function(name, value) {
			this.name = name;
			this.value = value;
		},
		element: function(cancelCallback) {
			var type = (this.name === "email" ? "email" : "text");
			var input = dom.input({
				name: this.inputName(),
				value: this.value,
				type: type
			}).focus(function() {
				$(this).parents("p").addClass("focus");
			}).blur(function() {
				$(this).parents("p").removeClass("focus");
			}).keydown(function(event) {
				if (event.keyCode === 27) { cancelCallback(); }
			});
			// TODO: catch RETURN and ESCAPE
			return input;
		}.cache("input"),
		inputName: function() { return Input.inputName(this.name); },
		isModified: function() {
			// TODO: compare current value of input against original value
		},
		activate: function() {},
		showError: function(errors) {
			var error = errors[0]
			, element = this.element()
			, errorWrap = dom.div(".error").append(dom.span().text(error)).hide();
			element.after(errorWrap);
			errorWrap.fadeIn(300);
		},
		hideError: function() {
			var error = this.element().next(".error");
			error.fadeOut(100, function() {
				error.remove();
			});
		}
	});

	Input.inputName = function(name) {
		return "user[" + name + "]";
	};

	var responseCallback = function(complete, successCallback, failCallback) {
		var isFunction = function(f) { return (typeof f === "function"); }
		return function(result, status) {
			if (status === "success") {
				if (isFunction(complete)) { complete(result); }
				if (isFunction(successCallback)) { successCallback(result); }
			} else {
				if (isFunction(failCallback)) { failCallback(result); }
			}
		}
	};

	var UserController = {
		save:   function(user, params, successCallback, failCallback) {
			var url = ["/users", user.get("id")].join("/");
			ajax.put(url, params, responseCallback(function(result) {
				user.update(result);
			}, successCallback, failCallback));
		},
		create: function(user, params, successCallback, failCallback) {
			var url = "/users";
			ajax.post(url, params, responseCallback(function(result) {
				user.update(result);
			}, successCallback, failCallback));
		},
		delete: function(user, successCallback, failCallback) {
			var url = ["/users", user.get("id")].join("/");
			ajax.del(url, {}, responseCallback(function(result) {

			}, successCallback, failCallback));
		},
		enable: function(user, enabled, successCallback, failCallback) {
			var action = (enabled ? "enable" : "disable")
			, url = ["/users", action, user.get("id")].join("/");
			ajax.put(url, {}, responseCallback(function(result) {
				user.set("disabled", !enabled);
			}, successCallback, failCallback));
		},
		logout: function(user, successCallback, failCallback) {
			var url = ["/users", "keys", user.get("id")].join("/");
			ajax.del(url, {}, responseCallback(function(result) {

			},successCallback, failCallback));
		},
	};

	var EditUserView = new JS.Class({
		initialize: function(parent, user) {
			this.parent = parent;
			this.user   = user;
		},
		titleText: function() {
			return "Editing User “" + this.user.get("name") + "”";
		},
		view: function() {
			var self = this;
			var user = this.user;
			var wrap = dom.div();
			var form = dom.form({method: "post", action: ajax.request_url("/users/"+ user.get("id"))})
			var inputs = {};
			var p, label, input, value;
			var titleBar = dom.div(".title").append(dom.span().text(this.titleText()));

			form.append(self.aboveUserAttributes());

			var cancel = function() {
				self.parent.closeUser();
			};
			self.editableAttributes().forEach(function(name) {
				p = dom.p()
				label = dom.label().text(name);
				input = self.inputForAttribute(name);
				value = dom.div(".value").append(input.element(cancel));
				p.append(label, value);
				form.append(p);
				inputs[name] = input;
			});
			p = dom.div('.save');
			var saveComplete = function() {
				self.parent.closeUser();
			};
			var saveFail = function(errors) {
				self.verificationErrors(errors);
			};
			var performSave = function() {
				self.beforeSave();
				self.save(form, saveComplete, saveFail);
				return false;
			};
			var cancelBtn = dom.a(".button.cancel").text("Cancel").click(cancel);
			var saveBtn = dom.button(".button", {type: "submit"}).text(self.saveButtonText()).click(performSave);
			p.append(cancelBtn, dom.div(".gap"), saveBtn);
			form.append(p);
			form.submit(performSave);
			this.inputs = inputs;
			form.find('input[type="text"]:first').focus().select();
			wrap.append(titleBar, form)
			return wrap;
		},
		verificationErrors: function(errors) {
			var self = this;
			$.each(errors, function(name, error) {
				self.inputs[name].showError(error);
			});
		},
		saveButtonText: function() {
			return "Save";
		},
		inputForAttribute: function(name) {
			if (name === "level") {
				return new LevelSelect(name, this.user);
			}
			return new Input(name, this.user.get(name));
		},
		editableAttributes: function() {
			return ["login", "name", "email", "level"];
		},
		aboveUserAttributes: function() {
			var self = this;
			var user = this.user
			var admin = dom.div(".admin");
			p = dom.p(".enabled");
			label = dom.label().text("Enabled");
			var checkbox = dom.input({type:"checkbox", checked: (!user.get("disabled"))}).click(function() {
				var enabled = $(this).attr("checked") === "checked";
				UserController.enable(user, enabled);
				return false;
			});
			user.watch("disabled", function(disabled) {
				checkbox.attr("checked", !disabled);
			});
			label.append(checkbox);
			p.append(label);
			admin.append(p);

			admin.append(dom.p(".gap"));
			p = dom.p(".log-off");
			var btn = dom.a(".button.log-out").text("Log "+user.get("login")+" Out").click(function() {
				var $this = $(this);
				$this.addClass("pending");
				UserController.logout(user, function() {
					$this.removeClass("pending").addClass("complete").text("Logged Out");
				});
			});
			p.append(btn);
			admin.append(p);
			return admin;
		},
		activate: function() {
			$.each(this.inputs, function(name, input) {
				input.activate();
			});
		},
		belowUserAttributes: function() {

		},
		serialiseForm: function(form) {
			var valueArray = form.serializeArray()
			, params = {};
			valueArray.forEach(function(input) {
				params[input.name] = input.value;
			});
			return params;
		},
		beforeSave: function() {
			var self = this;
			self.editableAttributes().forEach(function(name) {
				self.inputs[name].hideError();
			});
		},
		save: function(form, successCallback, failCallback) {
			var self = this
			, params = self.serialiseForm(form)
			UserController.save(self.user, params, successCallback, failCallback);
		}
	});

	var CreateUserView = new JS.Class(EditUserView, {
		titleText: function() {
			return "Create User";
		},
		aboveUserAttributes: function() {
			return "";
		},
		belowUserAttributes: function() {
			return "";
		},
		editableAttributes: function() {
			return ["login", "name", "email", "password", "level"];
		},
		saveButtonText: function() {
			return "Create";
		},
		save: function(form, successCallback, failCallback) {
			var self = this
			, params = self.serialiseForm(form)
			, callback = function(params) {
				if (typeof successCallback === "function") {
					successCallback(params);
				}
				self.parent.addUser(self.user);
			};

			UserController.create(self.user, params, callback, failCallback);
		}
	});
	var User = new JS.Class({
		include: S.Properties,
		initialize: function(dialogue, attributes) {
			var self = this;
			self.dialogue = dialogue;
			self.attributes = attributes;
			self.update(attributes);
		},
		update: function(attributes) {
			var self = this;
			$.each(attributes, function(key, val) {
				self.set(key, val);
			});
		},
	});

	var UserAdmin = new JS.Class({
		initialize: function() {
		},
		show: function(container) {
			// we use this as a single shared instance so that the state is maintanined
			// between visits
			if (this.outer) {
				container.append(this.outer);
				return;
			}
			var self = this;
			var outer = dom.div("#user-admin-container");
			var title = dom.div(".title.main").append(dom.span().text("CMS Users"));
			var contents = dom.div(".contents");
			var edit = dom.div(".edit").hide();
			var done = dom.a(".button.done").text("Done").click(function() {
				self.close();
			});
			var addWrapper = dom.div(".add-user")
			var addButton  = dom.a(".button.add").text("Create User").click(function() {
				self.createUser();
			});
			addWrapper.append(addButton);
			title.append(done);
			outer.append(title, contents, addWrapper, edit);

			this.outer = outer;
			this.titleContainer = title;
			this.contentsContainer = contents;
			this.editContainer = edit;
			container.append(outer)
			ajax.get("/users", this.ready.bind(this));
		},
		createUser: function() {
			var user = new User(this, {});
			this.openView(new CreateUserView(this, user));
		},
		addUser: function(user) {
			this.addUserEntry(user);
		},
		ready: function(userData) {
			var self = this;

			Level.levels = userData.levels.map(function(data) { return new Level(data); });
			self.users = userData.users.map(function(data) { return new User(self, data); });

			self.users.forEach(function(user) {
				self.addUserEntry(user);
			});
		},
		addUserEntry: function(user) {
			var entry = this.listEntry(user);
			user.listEntry = entry;
			this.contentsContainer.append(entry);
		},
		detach: function() {
			this.outer = this.outer.detach();
		},
		listEntry: function(user) {
			var self = this;
			var row = dom.div(".user");
			row.attr("id", "user-admin-" + user.get("id"));
			var cells = ["name", "level"].map(function(attr) {
				var div = dom.div().addClass(attr).text(user.get(attr)).click(function() {
					self.editUser(user)
					return false;
				});
				user.watch(attr, function(newValue) {
					div.text(newValue);
				});
				return div;
			});
			var disabledState = function(disabled) {
				if (disabled) {
					row.addClass("disabled");
				} else {
					row.removeClass("disabled");
				}
			};
			user.watch("disabled", disabledState);
			disabledState(user.get("disabled"));
			var del = dom.div(".delete").click(function() {
				self.confirmDeleteUser(user);
				return false;
			});
			cells.push(del);
			row.append.apply(row, cells)
			return row;
		},
		animationDuration: 300,
		editUser: function(user) {
			this.openView(new EditUserView(this, user));
		},
		openView: function(viewInstance) {
			var self = this;
			var animationDuration = self.animationDuration;
			var edit = this.editContainer.empty();
			var list = this.contentsContainer;
			var back = dom.div(".back");
			edit.append(back, viewInstance.view());
			edit.css({ left: "100%", opacity: 0 }).show();
			list.animate({ opacity: 0.2 }, animationDuration);
			edit.animate({ left: "48px", opacity: 1 }, animationDuration, "swing")
			viewInstance.activate();
		},
		closeUser: function() {
			var animationDuration = this.animationDuration;
			var edit = this.editContainer.empty();
			var list = this.contentsContainer;
			list.animate({ opacity: 1 }, animationDuration);
			edit.animate({ left: "100%", opacity: 0 }, animationDuration, function() {
				edit.empty().hide();
			});
		},
		confirmDeleteUser: function(user) {
			var dialogue = Spontaneous.Popover.open(event, new ConfirmDeletePopup(this, user));
		},
		deleteUser: function(user) {
			var url = ["/users", user.get("id")].join("/");
			ajax.del(url, {}, function(result, status) {
				if (status === "success") {
					user.listEntry.disappear();
				}
			});
		},
		close: function() {
			S.ContentArea.exitMeta();
		}
	});

	var ConfirmDeletePopup = new JS.Class(Spontaneous.Views.PieceView.ConfirmDeletePopup, {
		initialize: function(list, user) {
			this.list = list;
			this.user = user;
		},
		// width: function() {
		// 	return 208;
		// },
		title: function() {
			return "Delete user “" + (this.user.get("login")) + "”";
		},
		position_from_event: function(target) {
			var pos = this.position_from_element(target);
			pos.left += 40;
			return pos;
		},
		view: function() {
			var self = this, __entry = this.list;
			var w = dom.div('#popover-delete').click(function() {
				self.close();
				return false;
			});

			var ok = dom.a('.ok').text("Delete").click(function() {
				self.close();
				__entry.deleteUser(self.user);
				return false;
			});
			var cancel = dom.a('.cancel').text("Cancel");
			w.append(cancel, ok)
			return w;
		}
	});

	return UserAdmin;

}(jQuery, Spontaneous));
