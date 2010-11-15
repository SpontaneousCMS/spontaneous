console.log("Loading Ajax...");

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
			var success = function(data, textStatus, XMLHttpRequest) {
				callback.call(caller, data, textStatus, XMLHttpRequest);
			};
			$.ajax({
				'url': this.request_url(url),
				'success': success
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
