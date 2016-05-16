// console.log('Loading PageEntry...')

Spontaneous.Views.PagePieceView = (function($, S) {
	'use strict';
	var dom = S.Dom;

	var PagePieceView = new JS.Class(Spontaneous.Views.PieceView, {
		// will eventually overwrite panel()
		panel: function() {
			var self = this;
			var wrapper = dom.div(['entry-wrap page no-boxes', self.alias_class(), self.fields_class(), self.depth_class(), self.visibility_class()]);
			var contents = dom.div('.entry-contents');
			var inside = dom.div('.entry-inner');
			var outline = dom.div('.white-bg').mouseover(self.mouseover.bind(self)).mouseout(self.mouseout.bind(self)).click(self.edit.bind(self));
			inside.append(outline);
			contents.append(self.action_buttons(contents));
			if (self.content.type().is_alias()) {
				contents.append(self.alias_target_panel());
			} else {
				contents.append(self.page_title_panel());
			}

			var entry = dom.div('.entry');
			var fields = new Spontaneous.FieldPreview(self, '', true);
			var fields_panel = fields.panel();
			entry.append(fields_panel);
			inside.append(entry);
			var preview_area = self.create_edit_wrapper(inside);
			contents.append(preview_area);
			wrapper.append(contents, self.entry_spacer());
			self.wrapper = wrapper;
			self.outline = outline;
			self.fields_preview = fields_panel;
			return wrapper;
		},
		page_title_panel: function() {
			var self = this;
			var content = self.content;
			var wrapper = dom.div();
			var load = function() {
				S.Location.load_id(self.id());
			}
			var header = dom.div('.page-title').click(load);
			var path = dom.div('.page-path').text(content.content.path).click(load);
			var title = dom.a().html(content.title());
			var type = dom.span('.content-type').text(content.type().display_title(content));
			content.title_field().watch('value', function(t) { title.html(t); }.bind(this));
			header.append(title, type);
			wrapper.append(header, path);
			return wrapper;
		},
		// shows both a link to the alias and a link to the alias target
		alias_target_panel: function() {
			var content = this.content;
			var wrapper = dom.div();
			var click = function() { S.Location.load_id(content.id()); };
			var alias_click = function() { S.Location.load_id(content.target().page_id); };
			var target = dom.div('.alias-target');//.click(click);
			var icon = content.alias_icon;
			var type = dom.span('.content-type').text(content.type().display_title(content));
			var title = dom.a('.alias-title').html(content.content.title).click(click);
			var alias_title = dom.a('.alias-target-title').html(content.content.alias_title).click(alias_click);

			if (!content.has_fields()) { wrap.addClass('no-fields'); }

			if (icon) {
				var img = new Spontaneous.Image(icon);
				target.append(img.icon(60, 60).click(click));
			}
			var path = dom.div('.page-path').text(content.content.path).click(click);

			target.append(title, alias_title, type);
			return wrapper.append(target, path);
		},
	});
	return PagePieceView;
}(jQuery, Spontaneous));
