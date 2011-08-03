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
			$.ajax({
				'url': this.request_url(url),
				'type': 'post',
				'data': post_data,
				'success': success,
				'error': error
			});
		},
		request_url: function(url) {
			return this.namespace + url;
		}
	};
}(jQuery, Spontaneous));
