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

    return pad(n.toString(16).toUpperCase(), len);
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

/*
 * Recursively expand macro from table
 *
 *   word - a string
 *   symbols - an array of maps of symbol/value pairs
 *   ctx - the current context
 */
var resolveSymbols = function(word, symbols, ctx) {
  for (var i in symbols)
    if (symbols[i][word] !== undefined) {
      // Either call dynamic symbol function or lookup static symbol
      var value = typeof symbols[i][word] === 'function' ?
        symbols[i][word](ctx) : symbols[i][word];

      // Recurse
      return resolveSymbols(value, symbols, ctx);
    }

  return '' + word;
};
module.exports.resolveSymbols = resolveSymbols;

/* Resolve expressions within a set of tokens */
var resolveExpressions = function(tokens) {
  var t = [], token, match, opA = '', operators = [];

  // Iterate over every token
  for (var i = 0; i < tokens.length; i++) {
    token = new String(tokens[i]);

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
    } else if ((match = token.match(/^(~)(.+)/))) {
      // Calculate bitwise complements
      var n = new Number(match[2]);

      if (!isNaN(n))
        token = eval(match[1] + n);
    }

    // Hunt for the first numerical token
    if (operators.length < 1 && typeof token === 'number' && i < tokens.length - 2) {
      if (opA !== '') // Flush out a previous operand
        t.push('' + opA);

      opA = token;
    } else if (opA !== '' && token.toString().match(/^([\+\-\*^\/|&^]|(>>)|(<<))$/) && i < tokens.length - 1) {
      operators.push('' + token);
    } else if (opA !== '' && typeof token === 'number' && operators.length > 0) {
      t.push('' + eval('(' + opA + ')' + ' ' + operators.join(' ') + ' (' + token + ')'));
      return resolveExpressions(t.concat(tokens.slice(i + 1)))
    } else {
      if (opA !== '')
        t.push(opA);
      if (operators.length)
        t.push(operators.join(' '));

      opA = '', operators = [];

      t.push('' + token);
    }
  }

  return t;
};
module.exports.resolveExpressions = resolveExpressions;

/*
 * Tokenize a string
 *
 *   str - string to tokenize
 *   symbols - an array of maps of symbol/value pairs
 *   ctx - the tokenization context
 */
var tokenize = function(str, symbols, ctx) {
  symbols = symbols || [[]];
  ctx = ctx || {};
  var tokens = [];

  /*
   * The expandToken flag is used to determine whether to lookup the
   * current token in the macro table or to skip it. This is needed
   * for the symbol directives (.DEF, .UNDEF, etc), which requires the
   * argument token to be interpreted literally so as to be removed
   * from the macro table.
   */
  var expandToken = true;

  // Split str into words
  str.split(/[ 	]+/).forEach(function(token) {

    // Remove commas
    token = token.replace(/,$/, '');

    if (expandToken && typeof token.match === 'function') {
      // Resolve symbols, ignoring valid prefixes and suffixes
      var match = token.match(/^([\+\-~]?)([^:]+)([:]?)/);

      token = match[1] + resolveSymbols(match[2], symbols, ctx) + match[3];
    } else
      expandToken = true;

    // Don't expand the token after symbol directives
    if (token.match(/\.(def)|(defp)|(undef)/))
      expandToken = false;

    if (token !== '')
      tokens.push(token);
  });

  // Resolve numerical expressions
  tokens = resolveExpressions(tokens);

  return tokens;
};
module.exports.tokenize = tokenize;
