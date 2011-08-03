// console.log('Loading PageEntry...')

Spontaneous.PageEntry = (function($, S) {
	var dom = S.Dom;

	var PageEntry = new JS.Class(Spontaneous.Content, {
		// will eventually overwrite panel()
		// panel: function() {
		// 	var wrapper = dom.div(['entry-wrap page no-boxes', this.depth_class(), this.visibility_class()])
		// 	var contents = dom.div('.entry-contents');
		// 	var inside = dom.div('.entry-inner');
		// 	var outline = dom.div('.white-bg').mouseover(this.mouseover.bind(this)).mouseout(this.mouseout.bind(this)).click(this.edit.bind(this))
		// 	inside.append(outline)
		// 	contents.append(this.title_bar(contents));
		// 	if (this.type().is_alias()) {
		// 		contents.append(this.alias_target_panel());
		// 	}

		// 	contents.append(this.page_title_panel());
		// 	var entry = dom.div('.entry');
		// 	var fields = new Spontaneous.FieldPreview(this, '');
		// 	var fields_panel = fields.panel();
		// 	entry.append(fields_panel);
		// 	inside.append(entry);
		// 	var preview_area = this.create_edit_wrapper(inside);
		// 	contents.append(preview_area);
		// 	wrapper.append(contents, dom.div('.entry-spacer'));
		// 	this.wrapper = wrapper;
		// 	this.outline = outline;
		// 	this.fields_preview = fields_panel;
		// 	return wrapper;
		// },
		// page_title_panel: function() {
		// 	var wrapper = dom.div('.page-title'),
		// 	__content = this,
		// 	title = dom.a().text(this.content.title).click(function() {
		// 		S.Location.load_id(__content.id());
		// 	});
		// 	this.title_field().watch('value', function(t) {
		// 		title.text(t);
		// 	}.bind(this));
		// 	wrapper.append(title)
		// 	return wrapper;
		// }
	});
	return PageEntry;
})(jQuery, Spontaneous);
