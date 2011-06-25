// console.log('Loading PageEntry...')

Spontaneous.PageEntry = (function($, S) {
	var dom = S.Dom;

	var PageEntry = new JS.Class(Spontaneous.Entry, {
		// will eventually overwrite panel()
		panel: function() {
			console.log("Page")
			var wrapper = dom.div(['entry-wrap page', this.depth_class(), this.visibility_class()])
			var inside = dom.div('.entry-inner');
			var outline = dom.div('.white-bg').mouseover(this.mouseover.bind(this)).mouseout(this.mouseout.bind(this)).click(this.edit.bind(this))
			inside.append(outline)
			wrapper.append(this.title_bar(wrapper));
			if (this.type().is_alias()) {
				wrapper.append(this.alias_target_panel());
			}

			wrapper.append(this.page_title_panel());
			var entry = dom.div('.entry');
			var fields = new Spontaneous.FieldPreview(this, '');
			var fields_panel = fields.panel();
			entry.append(fields_panel);
			inside.append(entry);
			var preview_area = this.create_edit_wrapper(inside);
			wrapper.append(preview_area)
			this.wrapper = wrapper;
			this.outline = outline;
			this.fields_preview = fields_panel;
			return wrapper;
		},
		page_title_panel: function() {
			var wrapper = dom.div('.page-title'),
			__content = this,
			title = dom.a().text(this.content.title).click(function() {
				S.Location.load_id(__content.id());
			});
			this.title_field().add_listener('value', function(t) {
				title.text(t);
			}.bind(this));
			wrapper.append(title)
			return wrapper;
		}
	});
	return PageEntry;
})(jQuery, Spontaneous);
