console.log("Loading UploadManager...");


Spontaneous.UploadManager = (function($, S) {
	var dom = S.Dom;
	var upload_id = (new Date()).valueOf();
	var Upload = function(field, file) {
		this.field = field;
		this.file = file;
		this.id = upload_id++;
		this.position = 0;
		this.total = this.file.fileSize;
	};

	Upload.prototype = {
		start: function(manager) {
			this.manager = manager;
			this.xhr = new XMLHttpRequest();
			this.upload = this.xhr.upload;
			this.xhr.open("PUT", "/@spontaneous/upload/"+this.id, true);
			this.xhr.setRequestHeader('X-Filename', this.file.fileName);
			this.upload.onprogress = this.onprogress.bind(this);
			this.upload.onload = this.onload.bind(this);
			this.upload.onloadend = this.onloadend.bind(this);
			this.xhr.onreadystatechange = this.onreadystatechange.bind(this);
			this.xhr.send(this.file);
		},
		// While loading and sending data.
		onprogress: function(event) {
			console.log("Upload#onprogress", event);
			var position = event.position, total = event.total;
			this.position = position;
			this.manager.upload_progress(this);
		},
		// When the request has successfully completed.
		onload: function(event) {
			console.log("Upload#onload", event);
			// this.manager.upload_complete(this);
		},
		// When the request has completed (either in success or failure).
		onloadend: function(event) {
			console.log("Upload#onloadend", event);
			this.manager.upload_failed(this);
		},
		onreadystatechange: function(event) {
			var xhr = event.currentTarget;
			if (xhr.readyState == 4 && xhr.status === 200) {
				var result = JSON.parse(xhr.responseText);
				this.manager.upload_complete(this, result);
			}
			console.log("Upload#onreadystatechange", event);
		}
	}
	var UploadManager = {
		init: function(status_bar) {
			this.status_bar = status_bar;
			this.pending = [];
			this.completed = [];
			this.failed = [];
			this.current = null;
			this.updater = null;
			// this.init_progress_bar();
		},
		add: function(field, file) {
			this.pending.push(new Upload(field, file));
			console.log("UploadManager#add", field, file, this.pending);
			if (!this.current) {
				this.next();
			}
		},
		next: function() {
			if (this.current) { return; }
			if (this.pending.length === 0) {
				// the download queue is complete
				this.finished();
				return;
			}
			this.init_progress_bar();
			this.current = this.pending.pop();
			this.current.start(this);
		},
		finished: function() {
			this.completed = [];
			window.setTimeout(this.status_bar.hide.bind(this.status_bar), 1000);
		},
		init_progress_bar: function() {
			this.status_bar.show();
			if (this.progress_showing) { return; }
			var c = this.status_bar.progress_container();
			var total = $(dom.div, {"id":"progress-total", 'class':'bar'});
			var individual = $(dom.div, {"id":"progress-individual", 'class':'bar'});
			c.append(total).append(individual);
			this.bars = {
				total: total,
				individual: individual
			};
			this.progress_showing = true;
		},
		update_progress_bars: function() {
			var total = 0, completed = 0;
			for (var i = 0, ii = this.completed.length; i < ii; i++) {
				total += this.completed[i].total;
				completed += this.completed[i].total;
			}
			for (var i = 0, ii = this.pending.length; i < ii; i++) {
				total += this.pending[i].total;
			}

			if (this.current) {
				total += this.current.total;
				completed += this.current.position;
			}
			
			console.log("UploadManager#update_progress_bars", completed, total)
			this.set_bar_length('total', completed, total);
			if (this.current) {
				this.set_bar_length('individual', this.current.position, this.current.total);
			} else {
				this.set_bar_length('individual', 0, 0);
			}
		},
		set_bar_length: function(bar_name, position, total) {
			var bar = this.bars[bar_name], percent = (position/total) * 100;
			bar.css('width', percent+"%");
		},
		upload_progress: function(upload) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_complete", "completed upload does not match current")
			}
			// console.log("UploadManager#upload_progress", upload.file.fileName, position, total, (position/total))
			this.update_progress_bars();
		},
		upload_complete: function(upload, result) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_complete", "completed upload does not match current")
			}
			this.completed.push(this.current);
			this.current.field.set_value(result);
			this.current = null;
			console.log("UploadManager#upload_complete", result, this.pending, this.completed)
			this.next();
		},
		upload_failed: function(upload) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_complete", "completed upload does not match current")
			}
			this.failed.push(this.current);
			this.current = null;
			console.error("UploadManager#upload_failed", upload, this.failed)
			this.next();
		}
	};
	return UploadManager;
})(jQuery, Spontaneous);

