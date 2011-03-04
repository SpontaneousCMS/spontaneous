// test for features and redirect to some page if any aren't avilable
//
// FormData
// XHR.upload
//

// webkit compatilibity
if (!window.URL) {
	if (window.webkitURL) {
		window.URL = window.webkitURL;
	}
}
