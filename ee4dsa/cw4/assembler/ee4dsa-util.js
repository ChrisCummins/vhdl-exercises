/*
 * util.js - EE4DSA utility functions
 */

/*
 * Pad the number 'n' to with padding character 'z' to width
 * 'width'. If 'prefix' is true, pad the leading edge.
 */
function pad(n, width, z, prefix) {
  z = z || '0';
  n = n + '';
  // Pop out any html tags when calculating length
  var length = n.replace(/<\/?[a-zA-Z ="]+>/g, '').length;

  return length >= width ? n : prefix ?
    n + new Array(width - length + 1).join(z) :
    new Array(width - length + 1).join(z) + n;
}

/*
 * Casts a decimal integer to a hexadecimal string.
 */
var int2hex = function(n) {
  return n !== undefined ? new Number(n).toString(16).toUpperCase() : '';
};

/*
 * Casts a decimal integer to a 32 bit hexadecimal string (0 padded).
 */
var int2hex32 = function(n) {
  return n !== undefined ? pad(int2hex(n), 8) : '';
};

/*
 * Casts a decimal integer to a 24 bit hexadecimal string (0 padded).
 */
var int2hex24 = function(n) {
  return n !== undefined ? pad(int2hex(n), 6) : '';
};

/*
 * Casts a decimal integer to a 16 bit hexadecimal string (0 padded).
 */
var int2hex16 = function(n) {
  return n !== undefined ? pad(int2hex(n), 4) : '';
};

var hex2int = function(n) {
  return parseInt(n.replace(/^0x/, ''), 16);
};

/*
 * Recursively expand macro from table
 *
 *   word - a string
 *   macros - a map of macros -> expanded text
 */
var unMacrofy = function(word, macros) {
  return macros[word] !== undefined ? unMacrofy(macros[word], macros) : word;
};

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

/*
 * Convert a string into a signed integer.
 */
var requireint = function(word) {
  if (word !== undefined) {
    word = new String(word);

    if (word.match(/^0x[0-9a-f]+/))
      return hex2int(word);
    else if (word.match(/-?[0-9]+/))
      return word;
  }

  throw 'Failed to parse integer "' + word + '"';
};

var requireString = function(word) {
  if (word === undefined)
    throw 'Missing required string';

  return new String(word);
};

var requireAddress = function(word) {
  return int2hex24(requireUint(word));
};

var require16Address = function(word) {
  return int2hex16(requireUint(word));
};

var requireByte = function(word) {
  if (word !== undefined) {
    var i = requireUint(word);

    if (i >= 0 && i < 256)
      return pad(int2hex(i), 2);
  }

  throw 'Failed to parse byte "' + word + '"';
};

var requireReg = function(word) {
  if (word !== undefined)
    return requireByte(word.replace(/^r/, ''));

  throw 'Failed to parse reg "' + word + '"';
};
