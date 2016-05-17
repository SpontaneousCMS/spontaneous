(function(S, $) {
	var dom = S.Dom;

	console.log('modification status class')
	var ModificationStatus = new JS.Class(S.Views.View, {

		unwatchOthers: function() {
			console.log('must unwatch the modifciation state')
			this.content.unwatch('has_unpublished_changes', this.onModificationChange());
		},

		onModificationChange: function() {
			if (!this._onModificationChange) {
				this._onModificationChange = function(value) {
					if (value) {
						this.panel().slideDown(200);
					} else {
						this.panel().slideUp(200);
					}
				}.bind(this);
			}
			return this._onModificationChange;
		},

		panel: function(label) {
			if (!this._panel) {
				this._panel = this.createPanel(label);
			}
			return this._panel;
		},

		createPanel: function(label) {
			var self = this, content = self.content;
			content.watch('has_unpublished_changes', self.onModificationChange());
			var modifiedStatus = dom.div('.content--unpublished').hide();
			var modifiedText = dom.span('.content--unpublished-label').text(label || 'Modified');
			var modifiedDate = dom.span('.content--unpublished-date').text('Updated: ' + content.contentHashChangedAt().toString());
			modifiedStatus.append(modifiedText, modifiedDate);
			if (content.get('has_unpublished_changes')) {
				modifiedStatus.show();
			}
			return modifiedStatus;
		}
	});

	S.ModificationStatusPanel = ModificationStatus;

	return ModificationStatus;

}(Spontaneous, jQuery));

