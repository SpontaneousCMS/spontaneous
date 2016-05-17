Spontaneous.Field.Boolean = (function($, S) {
	var dom = S.Dom
		, _unprocessed_value_ = 'unprocessed_value';

	var BooleanField = new JS.Class(Spontaneous.Field.String, {
		edit: function() {
			var self = this
				, w = dom.div(dom.id(self.css_id()))
				, input = self.input() // ensure we have created the radio inputs $on & $off
				, labels = self.type.labels
				, label = function(label, radio) { return dom.label().text(label).prepend(radio); };

			w.append(label(labels['true'], self.$on), label(labels['false'], self.$off));
			return w;
		},

		generate_input: function() {
			var self = this
				, checked = ((self.get(_unprocessed_value_) === true) || (self.get(_unprocessed_value_) === 'true'))
				, click = function() { self.editor.field_focus(self.input()); }
				, on = dom.radio({name:self.form_name(), value: 'true', checked: checked})
				, off = dom.radio({name:self.form_name(), value: 'false', checked: !checked});

			self.$on = on;
			self.$off = off;
			return $(on).add(off).click(click);
		},

		edited_value: function() {
			return this.input().filter(':checked').val();
		}
	});

	return BooleanField;

})(jQuery, Spontaneous);

