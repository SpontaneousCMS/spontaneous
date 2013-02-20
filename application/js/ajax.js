// console.log("Loading Ajax...");

Spontaneous.Ajax = (function($, S) {
	"use strict";

	$.ajaxSetup({
		'async': true,
		'cache': false,
		'dataType': 'json',
		'ifModified': false
	});

	var csrfToken = S.csrf_token;

	var __authenticate = function(request) {
		request.setRequestHeader(S.csrf_header, csrfToken);
	};
	// wraps jQuery.ajax with a auth aware error catcher
	var __request = function(params) {
		var requestSuccessHandler = params["success"]
		, successHandler = function(data, textStatus, xhr) {
			requestSuccessHandler(data, textStatus, xhr)
		};
		var requestErrorHandler = params["error"]
		, errorHandler = function(xhr, textStatus, error_thrown) {
			console.log('caught http error', xhr, textStatus, error_thrown)
			if (xhr.status === 401) {
				S.Ajax.unauthorized();
			} else if (requestErrorHandler) {
				requestErrorHandler(xhr, textStatus, error_thrown);
			}
		};
		params['error'] = errorHandler;
		params['success'] = successHandler;
		params['beforeSend'] = function (request) {
			__authenticate(request);
		};
		$.ajax(params);
	};
	return {
		namespace: "/@spontaneous",
		// returns a modified xmlhttprequest that adds csrf headers
		// after #open is called.
		authenticatedRequest: function(request) {
			var xhr = new XMLHttpRequest();
			xhr.__open = xhr.open;
			xhr.open = function() {
				this.__open.apply(this, arguments);
				__authenticate(this);
			};
			return xhr;
		},
		authenticateRequest: function(request) {
			__authenticate(request);
		},
		get: function(url, data, callback) {
			if (typeof data === "function") {
				callback = data;
				data = {};
			}
			// var handle_response = function(data, textStatus, xhr) {
			// 	callback(data, textStatus, xhr);
			// };
			this.makeRequest("GET", url, data, callback)
			// __request({
			// 	'url': this.request_url(url),
			// 	'success': handle_response,
			// 	'ifModified': false,
			// 	'data': data,
			// 	'error': handle_response // pass the error to the handler too
			// });
		},
		put: function(url, data, callback) {
			this.makeRequest("PUT", url, data, callback);
		},
		del: function(url, data, callback) {
			this.makeRequest("DELETE", url, data, callback);
		},
		post: function(url, data, callback) {
			this.makeRequest("POST", url, data, callback);
		},
		patch: function(url, data, callback) {
			this.makeRequest("PATCH", url, data, callback);
		},
		makeRequest: function(method, url, data, callback) {
			var success = function(data, textStatus, xhr) {
				if (typeof callback === "function") {
					callback(data, textStatus, xhr);
				}
			};
			var error = function(xhr, textStatus, error_thrown) {
				var result = false;
				try {
					result = $.parseJSON(xhr.responseText);
				} catch (e) { }
				if (typeof callback === "function") {
					callback(result, textStatus, xhr);
				}
			};
			data = data || {};
			__request({
				'url': this.request_url(url),
				'type': method,
				'data': data,
				'success': success,
				'error': error
			});
		},
		unauthorized: function() {
			window.location.href = "/";
		},
		test_field_versions: function(target, fields, success, failure) {
			var version_data = {}, modified = 0;
			for (var i = 0, ii = fields.length; i < ii; i++) {
				var field = fields[i], key = "[fields]["+field.schema_id()+"]";
				if (field.is_modified()) {
					version_data[key] = field.version();
					modified++;
				}
			}
			if (modified === 0) { success(); }

			this.post(['/field/conflicts', target.id()].join('/'), version_data, function(data, textStatus, xhr) {
				if (textStatus === 'success') {
					success();
				} else {
					if (xhr.status === 409) {
						var field_map = {};
						for (var i = 0, ii = fields.length; i < ii; i++) {
							var f = fields[i];
							field_map[f.schema_id()] = f;
						}
						var conflicted_fields = [];
						for (var sid in data) {
							if (data.hasOwnProperty(sid)) {
								var values = data[sid], field = field_map[sid];
								conflicted_fields.push({
									field:field,
									version: values[0],
									values: {
										server_original: values[1],
										local_edited:  field.edited_value(),
										local_original:  field.original_value()
									}
								});
							}
						}
						failure(conflicted_fields)
					}
				}
			});
		},
		csrf_token: function() {
			return {'__token':csrfToken }
		},
		request_url: function(url, needs_key) {
			var path = this.namespace + url;
			if (needs_key) {
				path += "?"+$.param(this.csrf_token())
			}
			return path
		}
	};
}(jQuery, Spontaneous));
