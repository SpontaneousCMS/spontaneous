// console.log('Loading Side Bar...')

Spontaneous.SideBar = (function($, S) {
	var dom = S.Dom, Page = S.Page;

	var side_bar = {
		panel: function() {
			this.panel = dom.div('#side-bar');
			this.logo_panel = dom.div('#logo');
			this.page_info_panel = dom.div('.page-info');
			this.user_panel = dom.div('#user');
			this.panel.append(this.logo_panel).append(this.page_info_panel).append(this.user_panel);
			return this.panel;
		},
		location_changed: function(location) {
			console.log('page-loaded', location);
			this.page_info_panel.text(location.url);
		},
		spinner: function() {
			if (!this._spinner) {
				this._spinner = Spontaneous.Progress(this.logo_panel[0], 48, {
					spinner_fg_color: '#fff',
					period: 850
				});
			}
			return this._spinner;
		}
	};
	return side_bar;
})(jQuery, Spontaneous);
