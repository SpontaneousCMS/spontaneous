Spontaneous.Require = {
	pending: [],
	current: false,
	_completed: [],
	position: 0,
	async: true,
	init: function(asynchronous) {
		this.async = asynchronous;
		var body = document.body;
		var splash = document.createElement('div');
		splash.id = "script-load-splash";
			var progress_outer = document.createElement('div');
			progress_outer.id = "script-load-progress";
		if (this.async) {
			var progress_inner = document.createElement('div');
			progress_outer.appendChild(progress_inner);
			this.bar = progress_inner;
			this.progress(0);
		} else {
			progress_outer.className = "synchronous";
			progress_outer.innerHTML = "Loading...";
		}
		splash.appendChild(progress_outer);
		body.appendChild(splash);
		this.container = splash
	},
	remove: function() {
		document.body.removeChild(this.container);
	},
	progress: function(position) {
		this.position = position;
		var percent = ((this.completed()/this.total()) * 100);
		if (isNaN(percent)) { percent = 0; }
		this.bar.style.width = percent + '%';
	},
	completed: function() {
		var total = 0;
		for (var i = 0, ii = this._completed.length; i < ii; i++) {
			total += this._completed[i][1];
		}
		total += this.position;
		return total;
	},
	total: function() {
		var total = 0;
		for (var i = 0, ii = this.pending.length; i < ii; i++) {
			total += this.pending[i][1];
		}
		if (this.current) {
			total += this.current[1];
		}
		for (var i = 0, ii = this._completed.length; i < ii; i++) {
			total += this._completed[i][1];
		}
		return total;
	},
	add: function(script) {
		this.pending.push(script)
		if (!this.current) { this.next(); }
	},
	next: function() {
		if (this.pending.length === 0) {
			this.remove();
			Spontaneous.onload();
			return;
		}
		var s = this.pending.shift();
		this.current = s;
		if (this.async) {
			var xhr = new XMLHttpRequest();
			xhr.open("GET", s[0], true);
			var onprogress = (function(req) {
				return function(event) {
					req.onprogress(event);
				}
			})(this);
			var onreadystatechange = (function(req) {
				return function(event) {
					req.onreadystatechange(event);
				}
			})(this);
			xhr.onprogress = onprogress;
			xhr.onreadystatechange = onreadystatechange;
			xhr.send();
		} else {
			var body = document.body;
			var script = document.createElement('script');
			script.type = 'text/javascript';
			script.src = this.current[0];
			body.appendChild(script);
			this.current = false;
		}
	},
	onprogress: function(event) {
		this.progress(event.position);
	},
	onreadystatechange: function(event) {
		console.log(this)
		var xhr = event.currentTarget;
		if (xhr.readyState == 4 && xhr.status === 200) {
			var body = document.body;
			var script = document.createElement('script');
			script.type = 'text/javascript';
			script.text = xhr.responseText;
			body.appendChild(script)
			this._completed.push(this.current);
			this.position = 0;
			this.next();
		}
	}
};
Spontaneous.require = function(script) {
	Spontaneous.Require.add(script)
}
