// console.log('Loading BoxContainer...')

Spontaneous.BoxContainer = (function($, S) {
	var dom = S.Dom;

	var BoxContainer = new JS.Class(S.Views.View, {

		initialize: function(content, wrap_id) {
			this.callSuper(content);
			this.wrap_id = wrap_id;
			this.box_content_container = dom.div('.slot-content-wrapper');
		},

		panel: function() {
			var wrapper = dom.div([dom.id(this.wrap_id), 'slots']);

			wrapper.append(this.tab_bar());
			wrapper.append(this.box_content_container);
			var s = Spontaneous.State.active_box(this.content);
			this.activate_id(s);
			return wrapper;
		},
		tab_bar: function() {
			var self = this;
			if (this.boxes().length === 0) { return ''; }
			if (!this._tab_bar) {
				var bar = dom.ul('.slot-tabs');
				var clickFunction = function(i) {
					return function() {
						this.activate(i, true);
					}.bind(self);
				};
				for (var i = 0, boxes = this.boxes(), ii = boxes.length; i < ii; i++) {
					var box = boxes[i];
					var li = dom.li();
					li.text(box.name());
					li.append(dom.span('.down'));
					li.click(clickFunction(i));
					bar.append(li);
				}
				this._tab_bar = bar;
			}
			return this._tab_bar;
		},
		activate: function(box_index, manually) {
			var box = this.boxes()[box_index];
			if (box === this._active_box) { return; }
			$('li', this.tab_bar()).removeClass('active');
			$('li:nth-child('+(box_index+1)+')', this.tab_bar()).addClass('active');
			box.activate();
			this._active_box = box;
			if (manually) {
				Spontaneous.State.activate_box(this.content, box);
				this.content.set('box', box);
			}
		},
		activate_id: function(id) {
			if (id) {
				for (var i = 0, ss = this.boxes(), ii = ss.length; i < ii; i++) {
					var s = ss[i];
					if (ss[i].id() === id) {
						this.activate(i);
						return;
					}
				}
			}
			// just in case
			this.activate(0);
		},
		boxes: function() {
			var self = this;
			if (!this._boxes) {
				var _boxes = [], content_container = this.box_content_container;
				var f = function(i, box) {
					var view = new Spontaneous.Views.BoxView(box, content_container);
					self._subviews.push(view);
					_boxes.push(view);
				}.bind(this);
				$.each(this.content.boxes(), f);
				this._boxes = _boxes;
			}
			return this._boxes;
		}
	});
	return BoxContainer;
})(jQuery, Spontaneous);


