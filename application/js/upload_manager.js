// console.log("Loading UploadManager...");


Spontaneous.UploadManager = (function($, S) {
	var dom = S.Dom;
	var upload_id = (new Date()).valueOf();
	var Upload = new JS.Class({
		initialize: function(manager, target, file) {
			this.manager = manager;
			this.field_name = target.schema_id();
			this.uid = target.uid();
			this.target = target;
			this.target_id = target.id();
			this._position = 0;
			this.failure_count = 0;
			this.file = file;
			this.name = this.file.fileName;
			this._total = this.file.size;
			this.complete = false;
			this.upload_id = upload_id++;
		},
		position: function() {
			return this._position;
		},
		total: function() {
			return this._total;
		},
		start: function() {
			var form = new FormData();
			form.append('file', this.file);
			form.append('field', this.field_name);
			this.post("/file/replace/"+this.target_id, form);
		},

		post: function(url, form_data) {
			this.xhr = new XMLHttpRequest();
			this.upload = this.xhr.upload;
			this.xhr.open("POST", this.namespaced_path(url), true);
			this.upload.onprogress = this.onprogress.bind(this);
			this.upload.onload = this.onload.bind(this);
			this.upload.onloadend = this.onloadend.bind(this);
			this.upload.onerror = this.onerror.bind(this);
			this.xhr.onreadystatechange = this.onreadystatechange.bind(this);
			this.started = (new Date()).valueOf();
			this.xhr.send(form_data);
		},
		namespaced_path: function(path) {
			return S.Ajax.request_url(path, true);
		},
		// While loading and sending data.
		onprogress: function(event) {
			var position = event.position;
			this._position = position;
			this.time = (new Date()).valueOf() - this.started;
			this.manager.upload_progress(this);
		},
		// When the request has successfully completed.
		onload: function(event) {
		},
		// When the request has completed (either in success or failure).
		onloadend: function(event) {
			this.manager.upload_failed(this, event);
		},
		onreadystatechange: function(event) {
			var xhr = event.currentTarget;
			if (xhr.readyState == 4) {
				if (xhr.status === 200) {
					if (!this.complete) {
						var result = JSON.parse(xhr.responseText);
						this.manager.upload_complete(this, result);
						this.complete = true;
					}
				} else if (xhr.status === 409) {
					this.manager.upload_conflict(this, event);
				}
			}
		},

		onerror: function(event) {
			this.failure_count++;
			this.manager.upload_failed(this, event);
		}
	});
	var WrapUpload = new JS.Class(Upload, {
		start: function() {
			var form = new FormData();
			form.append('file', this.file);
			this.post(["/file/wrap", this.target_id].join('/'), form);
		}
	});
	var ShardedWrapUpload = new JS.Class(S.ShardedUpload, {
		path: function() {
			return ["/shard/wrap", this.target_id].join('/');
		},
	});
	var FormUpload = new JS.Class(Upload, {
		initialize: function(manager, target, form_data, size) {
			this.callSuper(manager, target, form_data)
			this.form_data = this.file;
			this._total = size;
			this.name = "Saving...";
		},
		start: function() {
			this.post(this.target.save_path(), this.form_data);
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
			this.targets = {};
		},
		// call to append call for image replacement to queue
		add: function(target, upload) {
			this.pending.push(upload);
			this.register(target);
		},
		register: function(target) {
			this.targets[target.uid()] = target;
		},
		unregister: function(target) {
			delete this.targets[target.uid()];
		},
		replace: function(field, file) {
			var uploader_class = Upload;
			if (S.ShardedUpload.supported()) {
				console.log('Using sharded uploader')
				uploader_class = S.ShardedUpload;
			}
			this.add(field, new uploader_class(this, field, file))
			if (!this.current) {
				this.next();
			}
		},
		// call to wrap files
		wrap: function(slot, files) {
			for (var i = 0, ii = files.length; i < ii; i++) {
				var file = files[i], upload, upload_class = WrapUpload;
				if (S.ShardedUpload.supported()) {
					console.log('Using sharded uploader')
					upload_class = ShardedWrapUpload;
				}
				upload = new upload_class(this, slot, file);
				this.add(slot, upload)
			}
			if (!this.current) {
				this.next();
			}
		},
		form: function(content, form_data, file_size) {
			var upload = new FormUpload(this, content, form_data, file_size);
			this.add(content, upload)
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
			// console.log('UploadManager.finished', this.pending);
			this.completed = [];
			this.status_bar.hide();
		},
		init_progress_bar: function() {
			this.status_bar.show();
			if (this.progress_showing) { return; }
			var c = this.status_bar.progress_container();
			var outer = dom.div('#progress-bars');
			var total = dom.div('#progress-total.bar');
			var individual = dom.div('#progress-individual.bar');
			var name = dom.div('#progress-name');
			var stats = dom.div('#progress-stats');
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
				total += this.completed[i].total();
			}
			for (var i = 0, ii = this.pending.length; i < ii; i++) {
				total += this.pending[i].total();
			}
			if (this.current) {
				total += this.current.total();
			}
			return total;
		},
		data_completed: function() {
			var completed = 0;
			for (var i = 0, ii = this.completed.length; i < ii; i++) {
				completed += this.completed[i].total();
			}
			if (this.current) {
				completed += this.current.position();
			}
			return completed;
		},
		update_progress_bars: function() {
			var total = this.data_total(), completed = this.data_completed();

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
				d += this.current.position();
			}
			return Math.round(((d/1024)/(t/1000)*10)/10);
		},
		time_estimate: function() {
			var remaining = this.data_total() - this.data_completed();
			var time = (remaining/1024) / this.rate();
			return (Math.round(time)) + 's';
		},
		set_bar_length: function(bar_name, position, total) {
			var bar = this.bars[bar_name], percent = (position/total) * 100;
			bar.css('width', percent+"%");
		},
		upload_progress: function(upload) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_progress", "completed upload does not match current")
			}
			var target = this.targets[upload.uid];
			if (target) {
				target.upload_progress(upload.position(), upload.total());
			}
			this.update_progress_bars();
		},
		upload_complete: function(upload, result) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_complete", "completed upload does not match current")
			}
			this.completed.push(this.current);
			this.total_time += this.current.time;
			this.total_data += this.current.position();
			var target = this.targets[upload.uid];
			if (target) {
				target.upload_complete(result);
			}
			this.current = null;
			this.next();
		},
		upload_failed: function(upload, event) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_complete", "completed upload does not match current")
			}
			this.failed.push(this.current);
			var target = this.targets[upload.uid];
			if (target) {
				target.upload_failed(event);
			}
			this.current = null;
			console.error("UploadManager#upload_failed", upload, this.failed)
			this.next();
		},
		upload_conflict: function(upload, event) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_complete", "completed upload does not match current")
			}
			var target = this.targets[upload.uid];
			if (target) {
				target.upload_conflict($.parseJSON(event.currentTarget.response));
			}
			this.current = null;
			console.error("UploadManager#upload_conflict", upload, event)
			this.next();
		},
		FormUpload: FormUpload,
		WrapUpload: WrapUpload
	};
	return UploadManager;
}(jQuery, Spontaneous));

