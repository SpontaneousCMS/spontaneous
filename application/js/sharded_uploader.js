// console.log("Loading UploadManager...");


Spontaneous.ShardedUploader = (function($, S) {
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
			console.log('Shard#start', this.blob, this.blob.size)
			// first hash the blob, when complete call #hash_complete
			var reader = new FileReader();
			console.log('reader', reader)
			reader.onload = function(event) {
				console.log('reader complete', event)
				this.compute_hash(reader.result);
			}.bind(this);
			reader.onerror = function(event) {
				console.error('error', event);
			};
			console.log('starting reader')
			reader.readAsArrayBuffer(this.blob);

		},

		// callback from reader
		compute_hash: function(array_buffer) {
			console.log('computing hash', array_buffer)
			var bytes = new Uint8Array(array_buffer);
			var sha = Crypto.SHA1(bytes);
			console.log('computed hash', sha)
			this.hash = sha
			// begin upload
			this.begin_upload();
		},
		remote_path: function() {
			return [S.Ajax.namespace, 'shard', this.hash].join('/');
		},
		begin_upload: function() {
			// test for existance of shard on server
			S.Ajax.get(['/shard', this.hash].join('/'), this, this.status_complete);
		},
		status_complete: function(data, status, xhr) {
			if (status === "success") {
				// we're actually done
				this.complete();
			} else {
				this.upload();
			}
		},

		upload: function() {
			// create the form and post it using the calculated hash
			// assigning the callbacks to myself.

			var form = new FormData(),
				path = [S.Ajax.namespace, 'shard', this.hash].join('/');
			form.append('file', this.blob);
			this.xhr = new XMLHttpRequest();
			this.upload = this.xhr.upload;
			this.xhr.open("POST", path, true);
			this.upload.onprogress = this.onprogress.bind(this);
			this.upload.onload = this.onload.bind(this);
			this.upload.onloadend = this.onloadend.bind(this);
			this.upload.onerror = this.onerror.bind(this);
			this.xhr.onreadystatechange = this.onreadystatechange.bind(this);
			this.started = (new Date()).valueOf();
			this.xhr.send(form);
		},

		complete: function() {
			this.blob = null;
			this.uploader.shard_complete(this);
		},
		onprogress: function(event) {
			var position = event.position;
			this.position = position;
			this.time = (new Date()).valueOf() - this.started;
			// this.target.upload_progress(position, this.total);
			this.uploader.upload_progress(this);
		},
		onload: function(event) {
		},
		onloadend: function(event) {
			console.error('shard upload failed', event);
		},
		onreadystatechange: function(event) {
			var xhr = event.currentTarget;
			console.log('shard#onreadystatechange', event, xhr)
			if (xhr.readyState == 4 && xhr.status === 200) {
				this.complete();
			}
		},

		onerror: function(event) {
		}
	});
	var ShardedUploader = new JS.Class(Spontaneous.UploadManager.Upload, {
		slice_size: 512000,
		initialize: function(manager, target, file) {
			this.callSuper();
			this.completed = [];
			this.current = null;
		},
		start: function() {
			console.log('starting sharded upload')
			this.start_with_index(0);
		},
		start_with_index: function(index) {
			if (index < this.shard_count()) {
				var shard = new Shard(this, index, this.slice(index));
				console.log('created shard', shard)
				this.current = shard;
				shard.start();
			} else {
				console.log('complete')
				this.finalize();
			}
		},
		finalize: function() {
			var path = ["/shard/replace", this.target_id].join('/'), form = new FormData(), shards = [];
			for (var i = 0, ii = this.completed.length; i < ii; i++) {
				shards.push(this.completed[i].hash);
			}
			console.log(shards);
			form.append('field', this.field_name);
			form.append('shards', shards.join(','))
			form.append('filename', this.file.fileName);
			this.post(path, form);
		},
		upload_progress: function(shard) {
			// console.log('upload_progresss', shard)
			this.manager.upload_progress(this);
		},
		position: function() {
			var _position = 0;
			for (var i = 0, cc = this.completed, ii = cc.length; i < ii; i++) {
				_position += cc[i].size;
			}
			_position += this.current.progress;
			return _position;
		},
		total: function() {
			return this.file.size;
		},
		shard_complete: function(shard) {
			// update the progress
			// and launch the next shard
			console.log('shard complete', shard);
			this.manager.upload_progress(this);
			this.completed.push(shard);
			this.start_with_index(shard.index + 1);
		},
		shard_count: function() {
			return Math.ceil(this.file.size / this.slice_size);
		},
		slice: function(n) {
			// file slicing methods have been normalised by compatibility.js
			console.log(this.file.size, n, n*this.slice_size);
			return this.file.slice(n * this.slice_size, (n+1) * this.slice_size);
		}

	});
	ShardedUploader.extend({
		supported: function() {
			return ((typeof window.File.prototype.slice === 'function') &&
				(typeof window.FileReader !== 'undefined') &&
				(typeof window.Uint8Array !== 'undefined'));
		}
	});
	return ShardedUploader;
}(jQuery, Spontaneous));
