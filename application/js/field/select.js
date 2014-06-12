
Spontaneous.Field.Select = (function($, S) {
	'use strict';

	var dom = S.Dom
, ajax = S.Ajax;

	var SelectField = new JS.Class(Spontaneous.Field.String, {
		edit: function() {
			var self = this
, type = this.type
, option_list = type.option_list
, wrapper = dom.div('.select-field-type')
			, callback;
			if (!option_list) {
				// dynamic, make ajax call
				callback = function(data) {
					self.append_select(wrapper, data);
				};
				ajax.get(this.optionsURL(), callback);
			} else {
				self.append_select(wrapper, option_list);
			}
			return wrapper;
		},

		optionsURL: function() {
			return ['/field/options', this.type.schema_id, this.content.id()].join('/');
		},

		append_select: function(wrapper, option_list) {
			var select = dom.select()
			, options = {}
			, selected = this.selectedValue();
			option_list.forEach(function(val) {
				var value = val[0]
				, label = val[1]
				, option = dom.option({'value': value}).text(label);
				options[value] = label;
				if (value == selected) { // only == so that strings successfully match ints
					option.attr('selected', 'selected');
				}
				select.append(option);
			});
			this._select = select;
			this._options = options;
			wrapper.append(select);
		},

		preview: function() {
			return this.parsedValue()[1];
		},

		parsedValue: function() {
			var value = this.get('value');
			if (!value) { return []; }
			return JSON.parse(this.get('value'));
		},

		selectedValue: function() {
			return this.parsedValue()[0];
		},

		edited_value: function() {
			var value = this._select.val()
			, label = this._options[value];
			return JSON.stringify([value, label]);
		}
	});

	return SelectField;
})(jQuery, Spontaneous);
