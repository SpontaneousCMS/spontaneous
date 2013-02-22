/**
 * Based on an original plugin "jquery-caret-position-getter"
 *
 * https://github.com/beviz/jquery-caret-position-getter
 *
 * @license under Apache license
 * @author Bevis Zhao (i@bevis.me, http://bevis.me)
 */
(function($) {
	"use strict";

	var calculator = {
		// key styles
		primaryStyles: ['fontFamily', 'fontSize', 'fontWeight', 'fontVariant',
'fontStyle', 'paddingLeft', 'paddingTop', 'paddingBottom', 'paddingRight',
'marginLeft', 'marginTop', 'marginBottom', 'marginRight', 'borderLeftColor',
'borderTopColor', 'borderBottomColor', 'borderRightColor', 'borderLeftStyle',
'borderTopStyle', 'borderBottomStyle', 'borderRightStyle', 'borderLeftWidth',
'borderTopWidth', 'borderBottomWidth', 'borderRightWidth', 'line-height',
'outline'],

specificStyle: {
	'white-space': 'pre-wrap',
'word-wrap': 'normal',
'overflow-x': 'hidden',
'overflow-y': 'auto'
},

simulator : $('<div id="textarea_simulator"/>').css({
	position: 'absolute',
top: 0,
left: 0,
visibility: 'hidden'
}).appendTo(document.body),

					// calculate position
					getSelectionPosition: function() {
						var cal = calculator, self = this, element = self[0], elementOffset = self.offset();

						cal.simulator.empty();
						// clone primary styles to imitate textarea
						$.each(cal.primaryStyles, function(index, styleName) {
							self.cloneStyle(cal.simulator, styleName);
						});

						// caculate width and height
						cal.simulator.css($.extend({
							'width': self.width(),
							'height': self.height()
						}, cal.specificStyle));

						var value = self.val(),
								selectStart = element.selectionStart,
								selectEnd = element.selectionEnd;

						if (selectEnd === selectStart) { return false; };

						var beforeText = value.substring(0, selectStart),
								selectedText = value.substring(selectStart, selectEnd),
								afterText = value.substring(selectEnd);

						var before = $('<span class="before"/>').html(beforeText),
								focus = $('<span class="focus"/>').html(selectedText),
								after = $('<span class="after"/>').html(afterText);

						cal.simulator.append(before, focus, after);

						var focusOffset = focus.offset(), simulatorOffset = cal.simulator.offset();

						return {
							top: focusOffset.top - simulatorOffset.top - element.scrollTop,
								left: focus[0].offsetLeft -  cal.simulator[0].offsetLeft - element.scrollLeft,
								width: focus.width(),
								height: focus.height()
						};
					}
};

var showPopup = function(textarea, popup, offsetCalculator) {
	var pos = calculator.getSelectionPosition.call(textarea);
	if (pos === false) {
		popup.hide();
		return false;
	}
	var position = textarea.position(), height = textarea.height(),
			top = position.top + pos.top, bottom = position.top + height;

	// In order to use the size of the popup in the positioning calculations
	// it needs to be visible in the dom.
	popup.css("visibility", "hidden").show();
	var place = offsetCalculator(pos);
	popup.hide().css("visibility", "visible");
	if (top >= position.top && top < bottom) {
		popup.css({
			left: place.left,
			top: place.top
		}).fadeIn(100)
	} else {
		popup.fadeOut(100);
	}
	return true;
}
$.fn.extend({
	getComputedStyle: function(styleName) {
		if (this.length == 0) return;
		var self = this[0], result = this.css(styleName);
		result = result || ($.browser.msie ? self.currentStyle[styleName]: document.defaultView.getComputedStyle(self, null)[styleName]);
		return result;
	},
cloneStyle: function(target, styleName) {
	var styleVal = this.getComputedStyle(styleName);
	if (!!styleVal) {
		$(target).css(styleName, styleVal);
	}
},
showSelectionPopup: function(popup, offsetCalculator) {
	var self = $(this);
	var callback = function() {
		var selected = showPopup(self, popup, offsetCalculator);
		if (!selected) {
			self.unbind("scroll.popup").unbind("mouseup.popup");
		}
	};
	self.bind("scroll.popup", callback);
	self.bind("mouseup.popup",  callback.delay(1));
	callback();
}
});
}(jQuery));

