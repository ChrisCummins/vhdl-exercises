/*
 * data - String
 * options - Object
 *    size - Number
 * callback - Function(err, data)
 */
var assemble = function(data, options, callback) {

  var asm2prog = function(lines) {
    var prog = {
      ramSize: options.size || 4096
    };


    return prog;
  };

  var prog2ram = function(prog, size) {
    return prog;
  };

  callback(0, prog2ram(asm2prog(data.split('\n'))));
};
