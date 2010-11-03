console.log('Loading Entry...')

Spontaneous.Entry = (function($, S) {
	var dom = S.Dom;

	var Entry = function(content, container) {
		this.content = content;
		this.container = container;
		console.log('FacetEntry#new', content);
	};
	Entry.prototype = $.extend({}, Spontaneous.Content, {
		save: function(form) {
			Spontaneous.Spin.start();
			console.log('saving', this.id, $(form).serialize())
			Spontaneous.Ajax.post('/'+this.model_name+'/'+this.id + '/save', $(form).serialize(), this, this.saved);
			return false;
		},
		panel: function() {
			var wrapper = $(dom.div, {'class':'entry-wrap'});
			wrapper.append($(dom.div, {'class':'white-bg'})).append($(dom.div, {'class':'grey-bg'}));
			var entry = $(dom.div, {'class':'entry level2'});
			var fields = new Spontaneous.FieldPreview(this, '');
			entry.append(fields.panel());
			console.log("Entry#panel", this.entries())
			var slot_container = new Spontaneous.SlotContainer(this.content);
			wrapper.append(entry);
			wrapper.append(slot_container.panel());
			return wrapper;
		}
	});
	return Entry;
})(jQuery, Spontaneous);
