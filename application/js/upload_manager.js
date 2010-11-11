console.log("Loading UploadManager...");


Spontaneous.UploadManager = (function($, S) {
	var dom = S.Dom;
	var upload_id = (new Date()).valueOf();
	var Upload = new JS.Class({
		initialize: function(manager, target, file) {
			this.manager = manager;
			this.target = target;
			this.id = upload_id++;
			this.position = 0;
			this.failure_count = 0;
			this.file = file;
			this.name = this.file.fileName;
			console.log(this.name)
			this.total = this.file.fileSize;
		},

		// only for direct image replacement
		start: function() {
			var form = new FormData();
			form.append('file', this.file);
			form.append('field', this.target.name);
			this.post("/@spontaneous/file/replace/"+this.target.id(), form);
		},
		post: function(url, form_data) {
			this.xhr = new XMLHttpRequest();
			this.upload = this.xhr.upload;
			this.xhr.open("POST", url, true);
			this.upload.onprogress = this.onprogress.bind(this);
			this.upload.onload = this.onload.bind(this);
			this.upload.onloadend = this.onloadend.bind(this);
			this.upload.onerror = this.onerror.bind(this);
			this.xhr.onreadystatechange = this.onreadystatechange.bind(this);
			this.started = (new Date()).valueOf();
			this.xhr.send(form_data);
		},
		// While loading and sending data.
		onprogress: function(event) {
			console.log("Upload#onprogress", event);
			var position = event.position;
			this.position = position;
			this.time = (new Date()).valueOf() - this.started;
			this.target.upload_progress(position, this.total);
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
			console.log("Upload#onreadystatechange", event);
			var xhr = event.currentTarget;
			if (xhr.readyState == 4 && xhr.status === 200) {
				var result = JSON.parse(xhr.responseText);
				this.manager.upload_complete(this, result);
			}
		},
		onerror: function(event) {
			this.failure_count++;
			this.manager.upload_failed(this);
		}
	});
	var WrapUpload = new JS.Class(Upload, {
		start: function() {
			var form = new FormData();
			form.append('file', this.file);
			this.post("/@spontaneous/file/wrap/"+this.target.id(), form);
		}
	});
	var FormUpload = new JS.Class(Upload, {
		initialize: function(manager, target, form_data, size) {
			this.callSuper(manager, target, form_data)
			this.form_data = this.file;
			this.total = size;
			this.name = "Saving...";
		},
		start: function() {
			console.log(this.form_data)
			this.post(['/@spontaneous/save', this.target.id()].join('/'), this.form_data);
		}
	});
	var UploadManager = {
		init: function(status_bar) {
			this.status_bar = status_bar;
			this.pending = [];
			this.completed = [];
			this.failed = [];
			this.current = null;
			this.updater = null;
			this.total_time = 0;
			this.total_data = 0;
			this.init_progress_bar();
			this.set_bar_length('individual', 1000, 2000)
			this.set_bar_length('total', 500, 2000)
			this.bars.name.text('Mobile Photo 3 Dec 2009 16 22 33.jpg');
			this.bars.stats.text('33Kb/s 3 mins remaining');
		},
		// call to append call for image replacement to queue
		replace: function(field, file) {
			this.pending.push(new Upload(this, field, file));
			console.log("UploadManager#add", field, file, this.pending);
			if (!this.current) {
				this.next();
			}
		},
		// call to wrap files
		wrap: function(slot, files) {
			for (var i = 0, ii = files.length; i < ii; i++) {
				var file = files[i];
				var upload = new WrapUpload(this, slot, file);
				this.pending.push(upload);
			}
			if (!this.current) {
				this.next();
			}
		},
		form: function(content, form_data, file_size) {
			var upload = new FormUpload(this, content, form_data, file_size);
			this.pending.push(upload);
			if (!this.current) {
				this.next();
			}
		},
		next: function() {
			if (this.current) { return; }
			if (this.pending.length === 0) {
				// the download queue is complete
				if (this.failed.length === 0) {
					this.finished();
				} else {
					var upload = this.failed.pop(), delay = Math.pow(2, upload.failure_count);
					console.log("UploadManager.next", "scheduling re-try of failed upload after", delay, "seconds");
					this.pending.push(upload);
					window.setTimeout(function() {
						console.log("UploadManager.next", "re-trying failed upload");
						this.next();
					}.bind(this),  delay * 1000);
				}
				return;
			}
			this.init_progress_bar();
			this.current = this.pending.shift();
			this.bars.name.text(this.current.name);
			this.current.start();
		},
		finished: function() {
			console.log('UploadManager.finished', this.pending);
			this.completed = [];
			window.setTimeout(this.status_bar.hide.bind(this.status_bar), 1000);
		},
		init_progress_bar: function() {
			this.status_bar.show();
			if (this.progress_showing) { return; }
			var c = this.status_bar.progress_container();
			var outer = $(dom.div, {'id':'progress-bars'});
			var total = $(dom.div, {"id":"progress-total", 'class':'bar'});
			var individual = $(dom.div, {"id":"progress-individual", 'class':'bar'});
			var name = $(dom.div, {'id': 'progress-name'});
			var stats = $(dom.div, {'id': 'progress-stats'});
			outer.append(individual);
			outer.append(total);
			c.append(outer);
			c.append(name).append(stats);
			this.bars = {
				total: total,
				individual: individual,
				name: name,
				stats: stats
			};
			this.progress_showing = true;
		},
		data_total: function() {
			var total = 0;
			for (var i = 0, ii = this.completed.length; i < ii; i++) {
				total += this.completed[i].total;
			}
			for (var i = 0, ii = this.pending.length; i < ii; i++) {
				total += this.pending[i].total;
			}
			if (this.current) {
				total += this.current.total;
			}
			return total;
		},
		data_completed: function() {
			var completed = 0;
			for (var i = 0, ii = this.completed.length; i < ii; i++) {
				completed += this.completed[i].total;
			}
			if (this.current) {
				completed += this.current.position;
			}
			return completed;
		},
		update_progress_bars: function() {
			var total = this.data_total(), completed = this.data_completed();

			console.log("UploadManager#update_progress_bars", completed, total)
			this.set_bar_length('total', completed, total);
			if (this.current) {
				this.set_bar_length('individual', this.current.position, this.current.total);
				this.bars.stats.text([this.rate(), 'Kb\/s', this.time_estimate()].join(' '));
			} else {
				this.set_bar_length('individual', 0, 0);
			}
		},
		rate: function() {
			var t = this.total_time, d = this.total_data;
			if (this.current) {
				t += this.current.time;
				d += this.current.position;
			}
			return Math.round(((d/1024)/(t/1000)*10)/10);
		},
		time_estimate: function() {
			var remaining = this.data_total() - this.data_completed();
			var time = (remaining/1024) / this.rate();
			return (Math.round(time*10)/10) + 's';
		},
		set_bar_length: function(bar_name, position, total) {
			var bar = this.bars[bar_name], percent = (position/total) * 100;
			bar.css('width', percent+"%");
		},
		upload_progress: function(upload) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_progress", "completed upload does not match current")
			}
			this.update_progress_bars();
		},
		upload_complete: function(upload, result) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_complete", "completed upload does not match current")
			}
			this.completed.push(this.current);
			this.total_time += this.current.time;
			this.total_data += this.current.position;
			this.current.target.upload_complete(result);
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

