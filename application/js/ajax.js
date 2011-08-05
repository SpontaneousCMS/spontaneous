// console.log("Loading Ajax...");

Spontaneous.Ajax = (function($, S) {
	$.ajaxSetup({
		'async': true,
		'cache': false,
		'dataType': 'json',
		'ifModified': true
	});
	return {
		namespace: "/@spontaneous",
		get: function(url, callback) {
			var handle_response = function(data, textStatus, xhr) {
				if (textStatus !== 'success') {
					xhr = data;
					data = {};
				}
				callback(data, textStatus, xhr);
			};
			$.ajax({
				'url': this.request_url(url),
				'success': handle_response,
				'data': this.api_access_key(),
				'error': handle_response // pass the error to the handler too
			});
		},
		post: function(url, post_data, callback) {
			var success = function(data, textStatus, XMLHttpRequest) {
				callback(data, textStatus, XMLHttpRequest);
			};
			var error = function(XMLHttpRequest, textStatus, error_thrown) {
				callback(false, textStatus, XMLHttpRequest);
			};
			post_data = $.extend(post_data, this.api_access_key());
			console.log(post_data)
			$.ajax({
				'url': this.request_url(url),
				'type': 'post',
				'data': post_data,
				'success': success,
				'error': error
			});
		},
		api_access_key: function() {
			return {'__key':Spontaneous.Auth.Key.load(S.site_id)}
		},
		request_url: function(url, needs_key) {
			var path = this.namespace + url;
			if (needs_key) {
				path += "?"+$.param(this.api_access_key())
			}
			return path
		}
	};
}(jQuery, Spontaneous));
