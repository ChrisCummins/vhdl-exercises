/*
 * util.js - EE4DSA utility functions
 */

/*
 * Pad the number 'n' to with padding character 'z' to width
 * 'width'. If 'prefix' is true, pad the leading edge.
 */
var pad = function(n, width, z, prefix) {
  z = z || '0';
  n = n + '';
  // Pop out any html tags when calculating length
  return n.length >= width ? n : prefix ?
    n + new Array(width - n.length + 1).join(z) :
    new Array(width - n.length + 1).join(z) + n;
};
module.exports.pad = pad;

/*
 * Casts a decimal integer to a hexadecimal string.
 */
var int2hex = function(n, len) {
  len = len || 8; // Default to 32 bits

  var max = (function(len) {
    var s = '0x';
    for (var i = 0; i < len; i++)
      s += 'f';

    return parseInt(s, 16);
  })(len);

  if (n !== undefined) {
    n = new Number(n);

    if (n < 0) // Twos complement
      n += max + 1;

    if (isNaN(n))
      throw 'Failed to convert number!';

    // Pad and truncate string as required
    var string = pad(n.toString(16).toUpperCase(), len);
    var start = string.length > len ? string.length - len : 0;

    return string.substring(start);
  }

  throw 'Failed to convert number "' + n + '"';
};
module.exports.int2hex = int2hex;

var hex2int = function(n) {
  var h = parseInt(n.replace(/^0x/, ''), 16);

  if (isNaN(h))
    throw 'Failed to parse integer "' + n + '"';

  return h;
};
module.exports.hex2int = hex2int;

/*
 * Convert a string into an unsigned integer.
 */
var requireUint = function(word) {
  if (word !== undefined) {
    word = new String(word);

    if (word.match(/^0x[0-9a-f]+/))
      return hex2int(word);
    else if (word.match(/[0-9]+/))
      return word;
  }

  throw 'Failed to parse integer "' + word + '"';
};
module.exports.requireUint = requireUint;

/*
 * Convert a string into a signed integer.
 */
var requireInt = function(word) {
  if (word !== undefined) {
    word = new String(word);

    if (word.match(/^0x[0-9a-f]+/))
      return hex2int(word);
    else if (word.match(/-?[0-9]+/))
      return new Number(word);
  }

  throw 'Failed to parse integer "' + word + '"';
};
module.exports.requireInt = requireInt;

var requireString = function(word) {
  if (word === undefined)
    throw 'Missing required string';

  return new String(word);
};
module.exports.requireString = requireString;

var requireAddress = function(word) {
  return int2hex(requireUint(word), 6);
};
module.exports.requireAddress = requireAddress;

var require16Address = function(word) {
  return int2hex(requireUint(word), 4);
};
module.exports.require16Address = require16Address;

var requireByte = function(word) {
  if (word !== undefined) {
    var i = requireUint(word);

    if (i >= 0 && i < 256)
      return int2hex(i, 2);
  }

  throw 'Failed to parse byte "' + word + '"';
};
module.exports.requireByte = requireByte;

var requireReg = function(word) {
  if (word !== undefined)
    return requireByte(new String(word).replace(/^r/, ''));

  throw 'Failed to parse reg "' + word + '"';
};
module.exports.requireReg = requireReg;

/* Flatten an array */
var flatten = function(array) {
  var result = [], self = arguments.callee;
  array.forEach(function(item) {
    Array.prototype.push.apply(result, Array.isArray(item) ? self(item) : [item]);
  });
  return result;
};
module.exports.flatten = flatten;

/* Count the number of items in object */
var len = function(obj) {
  counter = 0;

  for (var i in obj)
    counter++;

  return counter;
};
module.exports.len = len;

/* Convert ratio to percentage */
var perc = function(n, precision) {
  var n = new Number(n) * 100;

  if (precision !== undefined)
    n = +n.toFixed(precision);

  return n + '%';
};
module.exports.perc = perc;
