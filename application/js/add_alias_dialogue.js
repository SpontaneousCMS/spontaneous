
Spontaneous.AddAliasDialogue = (function($, S, window) {
	'use strict';
	var dom = S.Dom, Dialogue = Spontaneous.Dialogue;

	var Target = function(data, element) {
		this.id = data.id;
		this.data = data;
		this.element = element;
		this.selected = false;
	};
	Target.prototype = {
		redraw: function() {
			var el = this.element;
			if (this.selected) {
				if (!el.hasClass('selected')) {
					el.addClass('selected');
				}
			} else {
				if (el.hasClass('selected')) {
					el.removeClass('selected');
				}
			}
		}
	};

	var AddAliasDialogue = new JS.Class(Dialogue, {
		initialize: function(box_view, type, position) {
			this.box_view = box_view;
			this.box_view.bind('entry_added', this.alias_added.bind(this));
			this.type = type;
			this.insert_position = position;
			this.shiftSelectStartPosition = false;
		},
		title: function() {
			return 'Add &ldquo;'+(this.type.title)+'&rdquo; alias to &ldquo;' + this.box_view.name() + '&rdquo;';
		},
		buttons: function() {
			var btns = {};
			btns.Add = this.add_alias.bind(this);
			return btns;
		},

		cleanup: function() {
			this._outer.add(this._contents, window).unbind('mouseup.addAliasDialogue');
		},

		uid: function() {
			return this.content.uid() + '!add-alias';
		},
		add_alias: function() {
			var self = this, selected = self.selected();
			if (selected.length > 0) {
				self.box_view.add_alias(selected.map(function(target) { return target.id; }), self.type, self.insert_position);
			}
		},
		alias_added: function() {
			this.close();
		},
		selected: function() {
			return this.targets.filter(function(t) { return t.selected; });
		},
		// toggle a target in the list
		// returns true if the targe is in the list
		// false if not
		toggle_target: function(target, position, shiftKey) {
			var self = this, targets = self.shiftSelectTargets(target, position, shiftKey);
			if (target.selected) {
				self.remove_target(targets);
			} else {
				self.add_target(targets);
			}
		},

		remove_target: function(targets) {
			targets.forEach(function(target) {
				target.selected = false;
			});
			return false;
		},

		add_target: function(targets) {
			targets.forEach(function(target) {
				target.selected = true;
			});
			return true;
		},

		shiftSelectTargets: function(target, position, shiftKey) {
			var self = this, allTargets = self.targets, startPosition = self.shiftSelectStartPosition, targets = [target], i;
			if (!shiftKey) {
				self.shiftSelectStartPosition = position;
			} else {
				if (startPosition !== false) {
					if (position > startPosition) { // down
						for (i = startPosition + 1; i < position; i++) {
							targets.push(allTargets[i]);
						}
					} else if (position < startPosition) { // up
						for (i = startPosition - 1; i > position; i--) {
							targets.push(allTargets[i]);
						}
					}
				}
				self.shiftSelectStartPosition = false;
			}
			return targets;
		},
		box_owner: function() {
			return this.box_view.box.container;
		},
		box: function() {
			return this.box_view.box;
		},
		body: function() {
			var self = this
				, editing = dom.div('#add-alias-dialogue')
				, outer = dom.div('.typelist')
				, paging = dom.div('.paging')
				, search = dom.div('.search')
				, progress = dom.div('.progress')
				, instructions = dom.p('.instructions')
				, __dialogue = this
				, timeout = null
				, searchDelay = 200
				, clearTimeout = function() {
					if (timeout) { window.clearTimeout(timeout); timeout = null; }
				}
				, load_targets = function(query) {
					clearTimeout();
					var params = {};
					if (query !== '') {
						params.query = query;
					}

					self.spinner.start();
					Spontaneous.Ajax.get(['/alias', self.type.schema_id, self.box().id()].join('/'), params, self.targets_loaded.bind(self));
				}
				, input = dom.input({'type':'search', 'placeholder':'Search...'}).keydown(function(event) {
					if (event.keyCode === 13) {
						load_targets(input.val());
					}
					if (event.keyCode === 27) {
						if (input.val() === '') {
							return true;
						}
						input.val('');
						load_targets();
						return false;
					}
				}).keyup(function() {
					clearTimeout();
					var val = input.val();
					if (val === '' || val.length > 1) {
						timeout = window.setTimeout(function() {
							load_targets(val);
						}, searchDelay);
					}
				});
			instructions.html('Choose a target:');

			search.append(input);
			paging.append(progress, search);
			this.spinner = S.Progress(progress[0], 16);
			editing.append(paging, outer);
			load_targets();
			this.paging = paging;
			this._outer = outer;
			return editing;
		},

		targets_loaded: function(results) {
			var outer = this._outer, wrap, self = this, targets = self.sort_targets(results.targets);
			window.setTimeout(function() { self.spinner.stop(); }, 300);
			if (targets.length === 0) {
				var $msg = dom.div('.alias-dialogue-empty-targets').text('No targets available...');
				var $btn = dom.button().text('Close').click(Dialogue.close.bind(Dialogue));
				outer.append($msg.append($btn));
				return;
			}
			self.targets = [];
			outer.empty();
			wrap = dom.div();
			var _select = function(target, i) {
				return function(shiftKey) {
					self.toggle_target(target, i, shiftKey);
					self.redraw();
				};
			};
			$.each(targets, function(i, targetData) {
				var d = dom.div('.type');
				if (targetData.icon && targetData.icon.processed_value && targetData.icon.processed_value.__ui__) {
					var src = targetData.icon.processed_value.__ui__.src;
					var iconClasses = '.alias-icon'
					if (!src) {
						iconClasses += '.alias-icon-blank';
					}
					var i = dom.div(iconClasses).append(dom.img({src: src}));
					d.append(i)
				}
				var t = dom.div('.alias-title').html(targetData.title);
				d.append(t)
				var	target = new Target(targetData, d);
				d.mouseup(function(e) {
					if (!self.dragSelect) {
						_select(target, i)(false);
					}
				});
				d.mousedown(function(e) {
					self.dragSelect = true;
					_select(target, i)(e.shiftKey);
				});
				d.mouseenter(function(e) {
					if (self.dragSelect) {
						_select(target, i)(false);
					}
				});
				wrap.append(d);
				self.targets.push(target);
			});
			wrap.add(outer, window).bind('mouseup.addAliasDialogue', function() {
				if (self.dragSelect) {
					self.dragSelect = false;
				}
			});
			outer.append(wrap);
			self._contents = wrap;
			self.manager.updateLayout();
		},
		redraw: function() {
			this.targets.forEach(function(t) {
				t.redraw();
			});
		},
		contentsHeight: function() {
			return this.paging.outerHeight() + this._contents.outerHeight();
		},
		sort_targets: function(targets) {
			var comparator = function(a, b) {
				var at = a.title, bt = b.title;
				if (at > bt) { return 1; }
				if (at < bt) { return -1; }
				return 0;
			};
			return targets.sort(comparator);
		}
	});
	return AddAliasDialogue;
})(jQuery, Spontaneous, window);

