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
			var entry = $(dom.div, {'class':'entry'});
			var fields = new Spontaneous.FieldPreview(this, '');
			entry.append(fields.panel());
			// console.log("Entry#panel", this.entries())
			var slot_container = new Spontaneous.SlotContainer(this.content);
			wrapper.append(entry);
			wrapper.append(slot_container.panel());
			return wrapper;
		}
	});
	return Entry;
})(jQuery, Spontaneous);
