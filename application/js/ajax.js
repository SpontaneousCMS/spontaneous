// console.log("Loading Ajax...");

Spontaneous.Ajax = (function($, S) {
	$.ajaxSetup({
		'async': true,
		'cache': false,
		'dataType': 'json',
		'ifModified': true
	});
	// wraps jQuery.ajax with a auth aware error catcher
	var __request = function(params) {
		var requestErrorHandler = params["error"]
		, errorHandler = function(xhr, textStatus, error_thrown) {
			console.log('caught http error', xhr, textStatus, error_thrown)
			if (xhr.status === 401) {
				S.Ajax.unauthorized();
			} else if (requestErrorHandler) {
				requestErrorHandler(xhr, textStatus, error_thrown);
			}
		};
		params["error"] = errorHandler;
		$.ajax(params);
	};
	return {
		namespace: "/@spontaneous",

		get: function(url, data, callback) {
			if (typeof data === "function") {
				callback = data;
				data = {};
			}
			var handle_response = function(data, textStatus, xhr) {
				callback(data, textStatus, xhr);
			};
			__request({
				'url': this.request_url(url),
				'success': handle_response,
				'ifModified': true,
				'data': $.extend(data, this.api_access_key()),
				'error': handle_response // pass the error to the handler too
			});
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
		makeRequest: function(method, url, data, callback) {
			var success = function(data, textStatus, XMLHttpRequest) {
				if (typeof callback === "function") {
					callback(data, textStatus, XMLHttpRequest);
				}
			};
			var error = function(XMLHttpRequest, textStatus, error_thrown) {
				var result = false;
				try {
					result = $.parseJSON(XMLHttpRequest.responseText);
				} catch (e) { }
				if (typeof callback === "function") {
					callback(result, textStatus, XMLHttpRequest);
				}
			};
			data = data || {};
			data = $.extend(data, this.api_access_key());
			__request({
				'url': this.request_url(url, true),
				'type': method,
				'data': data,
				'success': success,
				'error': error
			});
		},
		unauthorized: function() {
			console.log("UNAUTH!")
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

			this.post(['/version', target.id()].join('/'), version_data, function(data, textStatus, xhr) {
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
