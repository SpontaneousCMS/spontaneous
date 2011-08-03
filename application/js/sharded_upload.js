// console.log("Loading ShardedUpload...");


Spontaneous.ShardedUpload = (function($, S) {
	var dom = S.Dom;
	var upload_id = (new Date()).valueOf();
	var Shard = new JS.Class({
		initialize: function(uploader, index, blob) {
			this.uploader = uploader;
			this.index = index;
			this.blob = blob;
			this.progress = 0;
			this.size = this.blob.size;
		},
		start: function() {
			var reader = new FileReader();
			reader.onload = function(event) {
				this.compute_hash(reader.result);
			}.bind(this);
			reader.onerror = function(event) {
				console.error('error', event);
			};
			reader.readAsArrayBuffer(this.blob);
		},

		// callback from reader
		compute_hash: function(array_buffer) {
			var bytes = new Uint8Array(array_buffer);
			var sha = Crypto.SHA1(bytes);
			this.hash = sha
			this.begin_upload();
			this.failure_count = 0;
		},
		remote_path: function() {
			return [S.Ajax.namespace, 'shard', this.hash].join('/');
		},
		begin_upload: function() {
			// test for existance of shard on server
			S.Ajax.get(['/shard', this.hash].join('/'), this.status_complete.bind(this));
		},
		status_complete: function(data, status, xhr) {
			if (status === "success") {
				// we're actually done
				this.complete();
			} else {
				this.upload();
			}
		},
		retry: function() {
			if (this.hash) {
				this.upload();
			} else {
				this.start();
			}
		},
		upload: function() {
			// create the form and post it using the calculated hash
			// assigning the callbacks to myself.

			var form = new FormData(),
				path = [S.Ajax.namespace, 'shard', this.hash].join('/');
			form.append('file', this.blob);
			var xhr = new XMLHttpRequest(), upload = xhr.upload;
			xhr.open("POST", path, true);
			upload.onprogress = this.onprogress.bind(this);
			upload.onload = this.onload.bind(this);
			upload.onloadend = this.onloadend.bind(this);
			upload.onerror = this.onerror.bind(this);
			xhr.onreadystatechange = this.onreadystatechange.bind(this);
			this.started = (new Date()).valueOf();
			xhr.send(form);
		},

		complete: function() {
			this.blob = null;
			this.uploader.shard_complete(this);
		},
		failed: function() {
			this.failure_count += 1;
			this.uploader.shard_failed(this);
		},
		onprogress: function(event) {
			var progress = event.position;
			this.progress = progress;
			this.time = (new Date()).valueOf() - this.started;
			this.uploader.upload_progress(this);
		},
		onload: function(event) {
		},
		onloadend: function(event) {
			console.error('Shard#onloadend: shard upload failed', event);
		},
		onreadystatechange: function(event) {
			var xhr = event.currentTarget;
			if (xhr.readyState == 4) {
				if (xhr.status === 200) {
					this.complete();
				} else {
					this.failed();
				}
			}
		},

		onerror: function(event) {
			console.error('Shard#onerror: shard upload error', event);
		}
	});

	var ShardedUpload = new JS.Class(Spontaneous.Upload, {
		slice_size: 524288,
		initialize: function(manager, target, file) {
			this.callSuper();
			this.completed = [];
			this.failed = [];
			this.current = null;
		},
		start: function() {
			this.started = (new Date()).valueOf();
			this.start_with_index(0);
		},
		start_with_index: function(index) {
			if (index < this.shard_count()) {
				var shard = new Shard(this, index, this.slice(index));
				this.current = shard;
				shard.start();
			} else {
				if (this.failed.length === 0) {
					this.finalize();
				} else {
					var shard = this.failed.pop();
					console.warn('retrying failed shard', shard)
					this.current = shard;
					shard.retry();
				}
			}
		},
		finalize: function() {
			var form = new FormData();
			form.append('field', this.field_name);
			form.append('shards', this.hashes().join(','));
			form.append('mime_type', this.mime_type());
			form.append('filename', this.file.fileName);
			this.post(this.path(), form);
		},
		path: function() {
			return ["/shard/replace", this.target_id].join('/');
		},
		hashes: function() {
			var hashes = [];
			for (var i = 0, ii = this.completed.length; i < ii; i++) {
				hashes.push(this.completed[i].hash);
			}
			return hashes;
		},
		upload_progress: function(shard) {
			this.time = (new Date()).valueOf() - this.started;
			this.manager.upload_progress(this);
		},
		position: function() {
			var _position = 0;
			for (var i = 0, cc = this.completed, ii = cc.length; i < ii; i++) {
				if (cc[i]) { // failed shards will leave a blank space
					_position += cc[i].size;
				}
			}
			_position += this.current.progress;
			return _position;
		},
		mime_type: function() {
			return this.file.type;
		},
		total: function() {
			return this.file.size;
		},
		shard_complete: function(shard) {
			// update the progress
			// and launch the next shard
			this.manager.upload_progress(this);
			this.completed[shard.index] = shard;
			this.start_with_index(shard.index + 1);
		},
		shard_failed: function(shard) {
			console.error('shard failed', shard, shard.index);
			this.failed.push(shard);
			this.start_with_index(shard.index + 1);
		},
		shard_count: function() {
			return Math.ceil(this.file.size / this.slice_size);
		},
		slice: function(n) {
			// file slicing methods have been normalised by compatibility.js
			return this.file.slice(n * this.slice_size, (n+1) * this.slice_size);
		}

	});
	ShardedUpload.extend({
		supported: function() {
			return ((typeof window.File.prototype.slice === 'function') &&
				(typeof window.FileReader !== 'undefined') &&
				(typeof window.Uint8Array !== 'undefined'));
		}
	});
	return ShardedUpload;
}(jQuery, Spontaneous));
