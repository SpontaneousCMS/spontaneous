// console.log("Loading Upload...");


Spontaneous.Upload = (function($, S) {
	var upload_id = (new Date()).valueOf();
	var Upload = new JS.Class({
		initialize: function(manager, target, file, insert_position) {
			this.manager = manager;
			this.field_name = target.schema_id();
			this.uid = target.uid();
			this.target = target;
			this.target_id = target.id();
			if (target.version) {
				this.target_version = target.version();
			}
			this._position = 0;
			this.failure_count = 0;
			this.file = file;
			this.insert_position = insert_position;
			console.log('upload insert at', insert_position)
			this.name = this.file.fileName;
			this._total = this.file.size;
			this.upload_id = upload_id++;
		},
		position: function() {
			return Math.min(this._total, this._position);
		},
		total: function() {
			return this._total;
		},
		start: function() {
			var form = new FormData();
			form.append('file', this.file);
			form.append('field', this.field_name);
			if (this.target_version) {
				form.append('version', this.target_version);
			}
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
			this.manager.upload_failed(this);
		},
		onreadystatechange: function(event) {
			var xhr = event.currentTarget;
			if (xhr.readyState == 4) {
				if (xhr.status === 200) {
					if (!this.complete) {
						console.log(xhr)
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
			this.manager.upload_failed(this);
		}
	});
	return Upload;
}(jQuery, Spontaneous));
