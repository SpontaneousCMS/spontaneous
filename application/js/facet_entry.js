console.log('Loading FacetEntry...')

Spontaneous.FacetEntry = (function($, S) {
	var dom = S.Dom;

	var FacetEntry = function(container, entry) {
		this.entry = entry;
		this.id = entry.id;
		this.type_id = entry.type_id;
		this.entries = entry.entries;
		this.is_page = entry.is_page;
		console.log('facet', entry);
	};
	FacetEntry.prototype = {
		save: function(form) {
			Spontaneous.Spin.start();
			console.log('saving', this.id, $(form).serialize())
			Spontaneous.Ajax.post('/'+this.model_name+'/'+this.id + '/save', $(form).serialize(), this, this.saved);
			return false;
		},

		position: function(position) {
			Spontaneous.Spin.start();
			console.log('moving', this.id, position)
			Spontaneous.Ajax.post('/'+this.model_name+'/'+this.id + '/position/'+position, {}, this, this.positioned);
			return false;
		},
		positioned: function(data) {
			Spontaneous.Spin.disappear(300);
		},
		model_name: 'facet',

		saved: function(data) {
			var updated_fields = data.fields;
			for (var i = 0, ii = updated_fields.length; i < ii; i++) {
				var f = updated_fields[i];
				this.field(f.name).update(f)
			}
			this.preview();
			Spontaneous.Spin.disappear(300);
		},

		depth: function() {
			return this.entry.depth;
		},

		field: function(name) {
			if (!this._field_map) { this.fields() };
			return this._field_map[name];
		},

		fields: function() {
			if (!this._fields) {
				this._fields = [], this._field_map = {};
				for (var i = 0, fields = this.entry.fields, ii = fields.length; i < ii; i++) {
					var field_class, field_data = fields[i];
					try {
						field_class = eval(field_data['class']);
					} catch (e) {
						console.log('unknown class', field_data['class']);
						field_class = Spontaneous.Field;
					}
					var f = new field_class(field_data);
					this._field_map[f.name] = f;
					this._fields.push(f);
				}
			}
			return this._fields;
		},

		entry_wrap: function() {
			if (!this._entry_wrap) {
				this._entry_wrap = $(dom.div, {'id':'entry-wrap_'+this.entry.id, 'class':'entry-container'});
				this._entry_wrap.data('facet', this);
				this.preview_content = this.preview_panel().preview()
				this._entry_wrap.append(this.preview_content);
				this.make_preview_draggable();
			}
			return this._entry_wrap;
		},

		preview: function() {
			this.edit_mode = false;
			if (this._entry_wrap) {
				this.preview_panel().preview();
				this._entry_wrap.removeClass('editing');
			}
			return this.entry_wrap();
		},

		edit: function() {
			if (this.edit_mode) { console.log('in edit mode');return; };
			this.edit_mode = true;
			console.log("*********", this._entry_wrap[0])
			this._entry_wrap.addClass('editing');
			this.preview_panel().edit();
		},

		preview_elements: ['title_bar', 'field_list', 'contents_list', 'bottom'],
		preview_panel:function() {
			if (!this._preview_panel) {
				this._preview_panel = new FacetEntry.FacetPreviewPanel(this);
			}
			// this.make_preview_draggable();
			return this._preview_panel;
		},

		make_draggable: function() {
		},

		make_preview_draggable: function() {
		},
		show_entry_add: function() {
			return false;
		}
	};

	FacetEntry.FacetFieldPanel = function(entry) {
		this.entry = entry;
	};

	FacetEntry.FacetFieldPanel.prototype = {
		preview: function() {
			if (!this.field_wrap) {
				console.log('recreating field_wrap for facet', this.entry.id)
				this.field_wrap = $(dom.div, {'class': 'field-wrap'});
				var to_edit = (function(entry) {
					return function() {
						console.log('to edit')
						entry.edit();
						return false;
					}
				})(this.entry);
				this.preview_wrap = $(dom.div, {'class':'preview'});
				this.preview_wrap.click(to_edit);
				for (var i = 0, fields = this.entry.fields(), ii = fields.length; i < ii; i++) {
					this.preview_wrap.append(fields[i].preview());
				}
				this.field_wrap.append(this.preview_wrap);
			}
			this.edit_mode = false;
			if (this.edit_wrap) { this.edit_wrap.hide(); }
			this.preview_wrap.show();
			return this.field_wrap;
		},
		edit: function() {
			if (this.edit_mode) { return; }
			this.edit_mode = true;
			if (!this.edit_wrap) {
				var save = (function(entry) {
					return function() {
						entry.save(this);
						return false;
					}
				})(this.entry);

				this.edit_wrap = $(dom.form, {'class':'edit'});

				var trigger_save = (function(form) {
					return function() {
						$(form).trigger('save');
						return false;
					};
				})(this.edit_wrap);
				this.edit_wrap.submit(trigger_save);
				this.edit_wrap.bind('save', save);

				for (var i = 0, fields = this.entry.fields(), ii = fields.length; i < ii; i++) {
					this.edit_wrap.append(fields[i].edit());
				}
				this.field_wrap.append(this.edit_wrap);
				this.save_button = $(dom.button, {'class':'save'}).text('Save')
				this.save_button.click(trigger_save);
				this.edit_wrap.append(this.save_button);
			}
			this.preview_wrap.hide();
			this.edit_wrap.show();
			this.entry.fields()[0].focus();
		}
	};

	FacetEntry.FacetContentsPanel = function(entry) {
		this.entry = entry;
	};

	FacetEntry.FacetContentsPanel.prototype = {
		type_buttons: [],
		preview: function() {
			if (!this.outer_wrap) {
				this.outer_wrap = $(dom.div)
				this.add_list_wrap = $(dom.div);
				var types = this.entry.type().allowed_types();
				console.log('** contents panel', this.entry, this.entry.type(), types)
				this.contents_wrap = $(dom.div, {'id':'contents-wrap-'+this.entry.entry.id, 'class': 'facet-contents-wrap'});;
				this.type_buttons = [];
				if (types.length > 0) {
					var inner = $(dom.div, {'class':'type-list'})
					this.add_list_wrap.addClass('facet-allowed')
					for (var i = 0, ii = types.length; i < ii; i++) {
						var button = $(dom.a, {'class':'type'}).text(types[i].name)
						this.type_buttons.push(button);
						inner.append(button);
					}
				} else {
				}
				this.add_list_wrap.append(inner);
				if (!this.entry.show_entry_add()) {
					this.add_list_wrap.hide();
				}
				this.outer_wrap.append(this.add_list_wrap);

				for (var i = 0, contents = this.entry.contents(), ii = contents.length; i < ii; i++) {
					var entry = contents[i];
					// console.log(entry);
					this.contents_wrap.append(entry.preview());
				};
				this.outer_wrap.append(this.contents_wrap);
			} else {
				if (!this.entry.show_entry_add()) {
					this.add_list_wrap.hide();
				}
				// this.outer_wrap.removeClass('editing');
			}
			return this.outer_wrap;
		},
		edit: function() {
			// this.outer_wrap.addClass('editing');
			this.add_list_wrap.show();
			this.make_preview_draggable();
		},
		make_preview_draggable: function() {
			console.log('>>>>> ', this.contents_wrap[0], this.entry.entry.depth(), '.facet-drag-bar.depth-'+this.entry.entry.depth())
			// http://jqueryui.com/demos/sortable/#default
			var stop = (function(entry) {
				return function(event, ui) {
					// console.log("...........", entry, ui, $(ui.item).data('facet'), ">>", entry.contents_wrap.sortable('toArray'));
					var facet = $(ui.item).data('facet');
					var id_order = entry.contents_wrap.sortable('toArray')
					for (var i = 0, ii = id_order.length; i < ii; i++) {
						var id = parseInt(id_order[i].split("_")[1], 10);
						if (id === facet.entry.id) {
							facet.position(i);
							break;
						}
					}
				};
			})(this);
			this.contents_wrap.sortable({
				revert: 100,
				// tolerance: 'pointer',
				items: '> .entry-container',
				containment: 'parent',
				axis: 'y',
				handle: '.facet-drag-bar.depth-'+(this.entry.entry.depth()+1),
				stop: stop
			});
			console.log('<<<< draggagle', '#'+this.contents_wrap.attr('id'))
			for (var i = 0, ii = this.type_buttons.length; i < ii; i++) {
				var button = this.type_buttons[i];
				button.draggable({
					connectToSortable: '#'+this.contents_wrap.attr('id'),
					helper: function() {
						return $(dom.div, {'class':'entry-container', 'style':'height: 100px;width: 100px;background-color: red'})[0];
					},
					revert: 'invalid'
				});
			}
		}
	};

	FacetEntry.FacetPreviewPanel = function(entry) {
		this.entry = entry;
	};
	FacetEntry.FacetPreviewPanel.prototype = {
		facet_wrap_class: function() {
			return 'facet depth-'+this.entry.depth();
		},
		edit: function() {
			var p = ['field_list', 'contents_list'];
			for (var i = 0, ii = p.length; i < ii; i++) {
				console.log('sending "edit" to', p[i], this.parts[p[i]])
				this.parts[p[i]].edit();
			}
		},
		preview: function() {
			if (!this.wrap) {
				this.parts = {};
				this.wrap = $(dom.div, {'class': this.facet_wrap_class()})
				for (var i = 0, ii = this.entry.preview_elements.length; i < ii; i++) {
					var part = this.entry.preview_elements[i];
					this.parts[part] = this[part]();
					if (typeof this.parts[part].preview === 'function') {
						this.wrap.append(this.parts[part].preview());
					} else {
						this.wrap.append(this.parts[part]);
					}
				}
			} else {
				var p = ['field_list', 'contents_list'];
				for (var i = 0, ii = p.length; i < ii; i++) {
					console.log('sending "preview" to', p[i], this.parts[p[i]])
					var part = this.parts[p[i]];
					if (part.preview) {
						part.preview();
					}
				}
			}
			return this.wrap;
		},
		make_draggable: function() {
			alert('facet_preview#make_draggable')
		},
		make_preview_draggable: function() {
			this.parts['contents_list'].make_preview_draggable();
		},
		title_bar: function() {
			var bar = (function(d) {
				return function() {
					return $(dom.div, {'class': 'facet-drag-bar depth-'+d})
				}
			})(this.entry.depth());
			return { preview: bar };
		},
		field_list: function() {
			return new FacetEntry.FacetFieldPanel(this.entry);
		},
		type: function() {
			return S.Types.type(this.entry.type_id);
		},
		add_list: function() {
		},
		contents: function() {
			if (!this._contents) {
				this._contents = [];
				for (var i = 0, entries = this.entry.entries, ii = entries.length; i < ii; i++) {
					var entry = entries[i];
					var klass = Spontaneous.FacetEntry;

					try {
						klass = eval(entry['class'] + "Entry");
					} catch (e) {
						console.error("unknown entry class", entry['class'] + "Entry")
					};
					this._contents.push(new klass(null, entry));
				}
			}
			return this._contents;
		},
		contents_list: function() {
			return new FacetEntry.FacetContentsPanel(this);
		},
		bottom: function() {
			return $(dom.div, {'class':'facet-bottom-bar'});
		},
		show_entry_add: function() {
			return this.entry.show_entry_add();
		}
	};
	return FacetEntry;
})(jQuery, Spontaneous);
