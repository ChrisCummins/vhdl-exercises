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
  var length = n.replace(/<\/?[a-zA-Z ="]+>/g, '').length;

  return length >= width ? n : prefix ?
    n + new Array(width - length + 1).join(z) :
    new Array(width - length + 1).join(z) + n;
};
module.exports.pad = pad;

/*
 * Casts a decimal integer to a hexadecimal string.
 */
var int2hex = function(n) {
  if (n !== undefined && !isNaN(n))
      return new Number(n).toString(16).toUpperCase();

  throw 'Failed to convert number "' + n + '"';
};
module.exports.int2hex = int2hex;

/*
 * Casts a decimal integer to a 32 bit hexadecimal string (0 padded).
 */
var int2hex32 = function(n) {
  return n !== undefined ? pad(int2hex(n), 8) : '';
};
module.exports.int2hex32 = int2hex32;

/*
 * Casts a decimal integer to a 24 bit hexadecimal string (0 padded).
 */
var int2hex24 = function(n) {
  return n !== undefined ? pad(int2hex(n), 6) : '';
};
module.exports.int2hex24 = int2hex24;

/*
 * Casts a decimal integer to a 16 bit hexadecimal string (0 padded).
 */
var int2hex16 = function(n) {
  return n !== undefined ? pad(int2hex(n), 4) : '';
};
module.exports.int2hex16 = int2hex16;

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
  return int2hex24(requireUint(word));
};
module.exports.requireAddress = requireAddress;

var require16Address = function(word) {
  return int2hex16(requireUint(word));
};
module.exports.require16Address = require16Address;

var requireByte = function(word) {
  if (word !== undefined) {
    var i = requireUint(word);

    if (i >= 0 && i < 256)
      return pad(int2hex(i), 2);
  }

  throw 'Failed to parse byte "' + word + '"';
};
module.exports.requireByte = requireByte;

var requireReg = function(word) {
  if (word !== undefined)
    return requireByte(word.replace(/^r/, ''));

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

/*
 * Recursively expand macro from table
 *
 *   word - a string
 *   symbols - an array of maps of symbol/value pairs
 */
var resolveSymbols = function(word, symbols) {
  for (var i in symbols)
    if (symbols[i][word] !== undefined)
      return resolveSymbols(symbols[i][word], symbols);

  return '' + word;
};
module.exports.resolveSymbols = resolveSymbols;

/* Resolve numerical expressions with a set of tokens */
var resolveExpressions = function(tokens) {
  var t = [], token, opA = '', operator = '';

  // Iterate over every token
  for (var i = 0; i < tokens.length; i++) {
    token = tokens[i];

    // Convert Hex digits to numbers
    if (token.match(/^0x[0-9a-f]+$/)) {
      var n = parseInt(token.replace(/^0x/, ''), 16);

      if (!isNaN(n))
        token = n;
    } else if (token.match(/^[-+]?[0-9]+$/)) {
      // Convert numbers to numbers
      var n = parseInt(token);

      if (!isNaN(n))
        token = n;
    }

    // Hunt for the first numerical token
    if (opA === '' && typeof token === 'number' && i < tokens.length - 2)
      opA = token;
    else if (opA !== '' && operator === '') {
      // If we have the first operand, then hunt for the operator
      if (token.toString().match(/^[\+\-\*^\/]$/))
        operator = token
      else {
        t.push('' + opA);
        t.push(token);
        opA = '';
      }
    } else if (opA !== '' && operator !== '') {
      // If we have the first operand and operator, then hunt for the last operand
      if (typeof token === 'number') {
        t.push('' + eval(opA + operator + token));
      } else {
        t.push('' + opA);
        t.push(operator);
        t.push('' + token);
        opA = '';
        operator = '';
      }
    } else {
      t.push('' + token);
    }
  }

  return t;
};
module.exports.resolveExpressions = resolveExpressions;

/* Tokenize a row */
var tokenize = function(str, symbols) {
  symbols = symbols || [[]];
  var tokens = [];

  /*
   * The expandToken flag is used to determine whether to lookup
   * the current token in the macro table or to skip it. This is
   * needed for the .UNDEF directive, which requires the
   * argument token to be interpreted literally so as to be
   * removed from the macro table.
   */
  var expandToken = true;

  // Split str into words
  str.split(/[ 	]+/).forEach(function(token) {

    // Remove commas
    token = token.replace(/,$/, '');

    // Expand macro
    if (expandToken)
      token = resolveSymbols(token, symbols);
    else
      expandToken = true;

    // Don't expand the token after .UNDEF directive
    if (token === '.undef')
      expandToken = false;

    if (token !== '')
      tokens.push(token);
  });

  // Resolve numerical expressions
  tokens = resolveExpressions(tokens);

  return tokens;
};
module.exports.tokenize = tokenize;
