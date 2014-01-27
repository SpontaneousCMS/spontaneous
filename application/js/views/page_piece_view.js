// console.log('Loading PageEntry...')

Spontaneous.Views.PagePieceView = (function($, S) {
	"use strict";
	var dom = S.Dom;

	var PagePieceView = new JS.Class(Spontaneous.Views.PieceView, {
		// will eventually overwrite panel()
		panel: function() {
			var wrapper = dom.div(['entry-wrap page no-boxes', this.depth_class(), this.visibility_class()])
			var contents = dom.div('.entry-contents');
			var inside = dom.div('.entry-inner');
			var outline = dom.div('.white-bg').mouseover(this.mouseover.bind(this)).mouseout(this.mouseout.bind(this)).click(this.edit.bind(this))
			inside.append(outline)
			contents.append(this.action_buttons(contents));
			if (this.content.type().is_alias()) {
				contents.append(this.alias_target_panel());
			}

			contents.append(this.page_title_panel());
			var entry = dom.div('.entry');
			var fields = new Spontaneous.FieldPreview(this, '', true);
			var fields_panel = fields.panel();
			entry.append(fields_panel);
			inside.append(entry);
			var preview_area = this.create_edit_wrapper(inside);
			contents.append(preview_area);
			wrapper.append(contents, this.entry_spacer());
			this.wrapper = wrapper;
			this.outline = outline;
			this.fields_preview = fields_panel;
			return wrapper;
		},
		page_title_panel: function() {
			var wrapper = dom.div('.page-title').click(function() {
				S.Location.load_id(self.id());
			}),
			self = this,
			content = self.content,
			title = dom.a().html(this.content.title()),
			type = dom.span(".content-type").text(content.type().display_title(content));
			this.content.title_field().watch('value', function(t) { title.html(t); }.bind(this));
			wrapper.append(title, type);
			return wrapper;
		}
	});
	return PagePieceView;
}(jQuery, Spontaneous));
