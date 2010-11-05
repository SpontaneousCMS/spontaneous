console.log("Loading UploadManager...");


Spontaneous.UploadManager = (function($, S) {
	var dom = S.Dom;
	var upload_id = (new Date()).valueOf();
	var Upload = function(field, file) {
		this.field = field;
		this.file = file;
		this.id = upload_id++;
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
		},
		add: function(field, file) {
			this.pending.push(new Upload(field, file));
			console.log("UploadManager#add", field, file, this.pending);
			if (!this.current) {
				this.next();
			}
		},
		next: function() {
			if (this.current || this.pending.length === 0) { return; }
			this.current = this.pending.pop();
			this.current.start(this);
		},
		upload_complete: function(upload, result) {
			if (upload !== this.current) {
				console.warn("UploadManager#upload_complete", "completed upload does not match current")
			}
			this.completed.push(this.current);
			this.current.field.set_value(result.path);
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

