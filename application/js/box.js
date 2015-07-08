// console.log('Loading Box...')

Spontaneous.Box = (function($, S) {
	var dom = S.Dom;

	var Box = new JS.Class(Spontaneous.Content, {

		initialize: function(content, container) {
			this.callSuper(content);
			this.container = container;
			var box = this;
			$.each(this.entries(), function(index, entry) {
				entry.bind('destroyed', function(entry) {
					box.entry_removed(entry);
				});
			});
		},

		name: function() {
			return this.type().title;
		},

		type: function() {
			if (!this._type) {
				this._type = this.container.type().box_prototype(this.content.id);
			}
			return this._type;
		},

		id: function() {
			return this.container.id() + '/' + this.schema_id();
		},

		schema_id: function() {
			return this.type().data.id;
		},

		depth: function() {
			return 'box';
		},

		isWritable: function() {
			return this.type().data.writable;
		},

		mouseover: function() {
			if (this.fields_preview) {
				this.fields_preview.addClass('hover');
			}
		},
		mouseout: function() {
			if (this.fields_preview) {
				this.fields_preview.removeClass('hover');
			}
		},

		re_sort: function(item) {
			var order = this._entry_container.sortable('toArray'), css_id = item.attr('id'), position = 0;
			for (var i = 0, ii = order.length; i < ii; i++) {
				if (order[i] === css_id) { position = i; break; }
			}
			var id = css_id.split('-')[1], entry;

			for (i = 0, entries = this.entries(), ii = entries.length; i < ii; i++) {
				if (entries[i].id() == id) { entry = entries[i]; break; }
			}
			entry.reposition(position, function(entry) {
				this.sorted(entry);
			}.bind(this));
		},
		sorted: function(entry) {
		},
		upload_complete: function(values) {
			this.insert_entry(this.wrap_entry(values.entry), values.position);
		},
		upload_progress: function(position, total) {
		},

		entry_id: function(entry) {
			return 'entry-' + entry.id();
		},

		entry_class: function() {
			return 'container-'+this.schema_id();
		},

		add_entry: function(type, position) {
			Spontaneous.Ajax.post(['/content', this.id(), type.schema_id].join('/'), {position: position}, this.entry_added.bind(this));
		},

		add_alias: function(alias_target_ids, type, position) {
			S.Ajax.post(['/alias', this.id()].join('/'), {'alias_id':type.schema_id, 'target_ids':alias_target_ids, 'position':position}, this.entries_added.bind(this));
		},

		entries_added: function(result) {
			var self = this;
			result.forEach(function(entry) {
				self.entry_added(entry);
			});
		},

		entry_added: function(result) {
			var box = this
			, position = result.position
			, e = result.entry
			, entry = this.wrap_entry(e);

			entry.bind('destroyed', function(entry) {
				box.entry_removed(entry);
		 	});
			if (position === -1) {
				this.content.entries.push(e);
				this.entries().push(entry);
			} else {
				this.content.entries.splice(position, 0, e);
				this.entries().splice(position, 0, entry);
			}
			var page = S.Editing.get('page');
			page.trigger('entry_added', entry, position);
			this.trigger('entry_added', entry, position);
		},

		entry_removed: function(entry) {
			var entries = this.entries(), position = 0;
			for (var i = 0, ii = entries.length; i < ii; i++) {
				if (entries[i].id() == entry.id()) {
					position = i;
					break;
				}
			}
			entries.splice(position, 1);
			this.trigger('entry_removed', entry);
		},

		// save_path: function() {
		// 	return [this.id()].join('/');
		// },
		entry_wrappers: function() {
			return this._entry_container.find('> .'+this.entry_class());
		},

		contentVisibilityToggle: function(affected) {
			this.entries().forEach(function(entry) {
				entry.contentVisibilityToggle(affected);
			});
		}
	});

	return Box;

})(jQuery, Spontaneous);
