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
		get: function(url, caller, callback) {
			var handle_response = function(data, textStatus, xhr) {
				if (textStatus !== 'success') {
					xhr = data;
					data = {};
				}
				callback.call(caller, data, textStatus, xhr);
			};
			$.ajax({
				'url': this.request_url(url),
				'success': handle_response,
				'error': handle_response // pass the error to the handler too
			});
		},
		post: function(url, post_data, caller, callback) {
			var success = function(data, textStatus, XMLHttpRequest) {
				callback.call(caller, data, textStatus, XMLHttpRequest);
			};
			var error = function(XMLHttpRequest, textStatus, error_thrown) {
				callback.call(caller, false, textStatus, XMLHttpRequest);
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
