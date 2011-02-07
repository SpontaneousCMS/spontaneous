// test for features and redirect to some page if any aren't avilable
//
// FormData
// XHR.upload
//

// for Firefox 4 compatibility
if (window.URL && typeof window.URL.createObjectURL === "function") {
	// why does FireFox always have to find a different name for everything?
	window.createBlobURL = function(file) {
		return window.URL.createObjectURL(file);
	}
}
// for chrome compatibility
if (window.createObjectURL) {
	window.createBlobURL = function(file) {
		return window.createObjectURL(file);
	}
}
