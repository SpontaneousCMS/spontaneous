console.log('Loading Extensions...')

// Thank you Prototype
function $A(iterable) {
  if (!iterable) return [];
  if (iterable.toArray) return iterable.toArray();
  var length = iterable.length || 0, results = new Array(length);
  while (length--) results[length] = iterable[length];
  return results;
}

jQuery.extend(Function.prototype, {
	bind: function() {
		var __method = this, args = $A(arguments), object = args.shift();
		return function() {
      return __method.apply(object, args.concat($A(arguments)));
    };
	}
});
