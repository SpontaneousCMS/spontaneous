console.log('Loading Entry...')

Spontaneous.Entry = (function($, S) {
	var dom = S.Dom;

	var Entry = new JS.Class(Spontaneous.Content, {
		initialize: function(content, container) {
			this.callSuper(content);
			// this.content = content;
			this.container = container;
			// console.log('FacetEntry#new', content, content.depth);
		},
		save: function(form) {
			Spontaneous.Spin.start();
			// console.log('saving', this.id, $(form).serialize())
			Spontaneous.Ajax.post('/'+this.model_name+'/'+this.id + '/save', $(form).serialize(), this, this.saved);
			return false;
		},
		panel: function() {
			var wrapper = $(dom.div, {'class':'entry-wrap ' + this.depth_class()});
			wrapper.append($(dom.div, {'class':'white-bg'}))
			if (this.depth() < 4) {
				wrapper.append($(dom.div, {'class':'grey-bg'}));
			}
			wrapper.append(this.title_bar(wrapper));
			this.dialogue_box = $(dom.div, {'class':'dialogue', 'style':'display: none'});
			wrapper.append(this.dialogue_box);
			var entry = $(dom.div, {'class':'entry'});
			var fields = new Spontaneous.FieldPreview(this, '');
			entry.append(fields.panel());
			// console.log("Entry#panel", this.entries())
			var slot_container = new Spontaneous.SlotContainer(this.content);
			wrapper.append(entry);
			wrapper.append(slot_container.panel());
			this.wrapper = wrapper;
			return wrapper;
		},
		title_bar: function(wrapper) {
			if (!this._title_bar) {
				var title_bar = $(dom.div, {'class':'title-bar'});
				var actions = $(dom.div, {'class':'actions', 'style':'display: none'});
				var destroy = $(dom.a, {'class':'delete'});
				actions.append(destroy);
				title_bar.append(actions);
				wrapper.mouseenter(function() {
					actions.slideDown(100);
				}).mouseleave(function() {
					actions.slideUp(100);
				});
				destroy.click(this.confirm_destroy.bind(this));
				this._title_bar = title_bar;
			}
			return this._title_bar;
		},
		confirm_destroy: function() {
			var d = this.dialogue_box;
			d.empty();
			var msg = $(dom.p, {'class':'message'}).text('Are you sure you want to delete this?');
			var btns = $(dom.div, {'class':'buttons'});
			var ok = $(dom.a, {'class':'default'}).text("Delete").click(function() {
				this.dialogue_box.slideUp(100, function() {
					this.wrapper.fadeTo(100, 0.5);
					this.destroy();
				}.bind(this));
				return false;
			}.bind(this))

			var cancel = $(dom.a).text("Cancel").click(function() {
				this.dialogue_box.slideUp();
				return false;
			}.bind(this));
			btns.append(ok).append(cancel);
			d.append(msg).append(btns);
			d.slideDown(200);
		},
		destroyed: function() {
			console.log('Entry.destroyed', this.content)
			this.wrapper.slideUp(200, function() {
				this.wrapper.remove();
			}.bind(this));
		}
	});
	return Entry;
})(jQuery, Spontaneous);
