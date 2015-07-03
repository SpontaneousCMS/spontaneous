
Spontaneous.Views = (function($, S) {
	var dom = S.Dom;
	var View = new JS.Class({
		include: Spontaneous.Properties,
		initialize: function(content) {
			this.content = content;
			this._subviews = [];
		},
		unload: function() {
			this.unwatchOthers();
			this.unloadView();
			this.unloadChildren();
		},
		unloadView: function() {
			// cleanup
		},
		onDOMAttach: function() {
			this.attachView();
			for (var i = 0, ii = this._subviews.length; i < ii; i++) {
				var v = this._subviews[i];
				if (v.onDOMAttach) {
					v.onDOMAttach();
				}
			}
		},
		attachView: function() {
		},
		unloadChildren: function() {
			for (var i = 0, c = this._subviews, ii = c.length; i < ii; i++) {
				if (typeof c[i].unload === 'function') {
					c[i].unload();
				} else {
					console.warn('unable to unload child view', c[i]);
				}
			}
		},
		id: function() {
			return this.content.id();
		},
		uid: function() {
			return this.content.uid();
		},
		depth_class: function() {
			return 'depth-'+this.content.depth();
		},
		depth: function() {
			return this.content.depth();
		},
		visibility_class: function() {
			return this.content.hidden() ? 'hidden' : 'visible';
		},
		alias_class: function() {
			return this.content.type().is_alias() ? 'alias' : 'not-alias';
		},
		fields_class: function() {
			return this.content.has_fields() ? 'fields' : 'no-fields';
		},
		boxes_class: function() {
			return this.content.has_boxes() ? 'boxes' : 'no-boxes';
		},

		has_fields: function() {
			return this.content.field_list().length > 0;
		},
		field_list: function() {
			return this.content.field_list();
		},
		image_fields: function() {
			return this.content.image_fields();
		},
		text_fields: function() {
			return this.content.text_fields();
		},
		string_values: function() {
			return this.content.string_values();
		},
		file_fields: function() {
			return this.content.file_fields();
		},
		mouseover: function(event) {
		},
		mouseout: function(event) {
		},
		save_path: function() {
			return this.content.save_path();
		},
		create_edit_wrapper: function(read_content) {
			var s = {'style':'position: relative; overflow: hidden;'};
			var outer = dom.div('.edit-wrapper-outer', s);
			var write = dom.div({'style':'position: absolute; height: 0; overflow: hidden;'});
			var write_inner = dom.div();
			var read = dom.div(s);
			var read_inner = dom.div();
			write.append(write_inner);
			read_inner.append(read_content);
			read.append(read_inner);
			outer.append(write).append(read);
			this.editing_area = {
				outer: outer,
				write: write,
				write_inner: write_inner,
				read: read,
				read_inner: read_inner
			};
			return outer;
		},

		edit: function(focus_field) {
			var time_to_reveal = 300, back = 10, front = 20,
				a = this.editing_area, o = a.outer, w = a.write, r = a.read, wi = a.write_inner, ri = a.read_inner;
			var panel = new Spontaneous.EditPanel(this), view = panel.view();
			r.css('z-index', front);
			w.css('z-index', back).css('height', 'auto').show();
			wi.append(view);
			var h = wi.outerHeight();
			o.add(r).animate({'height':h}, { queue: false, duration: time_to_reveal });
			w.css({'position':'relative'});
			r.css({'position':'absolute', 'top':0, 'right':0, 'left':0}).animate({'top':h}, { queue: false, duration: time_to_reveal, complete:function() {
				w.css({'z-index': front, 'position':'relative', 'height':'auto'});
				r.css({'z-index': back, 'position':'absolute', 'display':'none'});
				o.css('height', 'auto');
				panel.on_show(focus_field);
			}});
		},
		edit_closing: false,
		edit_closed: function() {
			if (this.edit_closing) { return; }
			this.edit_closing = true;
			var time_to_reveal = 300, back = 10, front = 20,
			a = this.editing_area, o = a.outer, w = a.write, r = a.read.css('display', 'block'), wi = a.write_inner, ri = a.read_inner, __content = this, h = ri.outerHeight();
			o.add(r).animate({'height':h}, { queue: false, duration: time_to_reveal });
			r.css({'z-index':front, 'height':h, 'top':wi.outerHeight()+'px'}).animate({'top':0}, { queue: true, duration: time_to_reveal, complete: function() {
				w.css({'position':'absolute', 'z-index':back});
				r.css({'position':'relative', 'height':'auto', 'z-index':front});
				o.css('height', 'auto');
				wi.empty();
				__content.edit_closing = false;
			}});
		},
		save_complete:function(response) {
			this.content.save_complete(response);
		}
	});
	return {
		View: View
	};
}(jQuery, Spontaneous));
