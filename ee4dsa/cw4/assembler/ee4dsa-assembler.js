/*
 * data - String
 * options - Object
 *    size - Number
 * callback - Function(err, data)
 */
var assemble = function(data, options, callback) {

  var asm2prog = function(lines) {
    var prog = {
      size: options.size || 4096,
      instructions: {},
      memory: {},
      labels: [],
      macros: {
        'null': 'r0',
        'sp': 'r1',
        'sreg': 'r2'
      }
    };

    // Keep track of where we are in the memory
    var memoryCounter = 0;

    // Keep track of whether we're dealing with code or data
    var currentSegment = 'cseg';

    // Iterate over lines
    for (var i in lines) {

      // Pre-process: trim comments & white space, lower case the text
      var line = lines[i].replace(/;.*/, '').trim().toLowerCase();

      // Skip empty lines
      if (line === '')
        continue;

      // Tokenize each line
      var tokens = (function(line) {
        var tokens = [];

        // Split line into words
        line.split(/[ \t]+/).forEach(function(token) {

          // Remove commas
          token = token.replace(/,$/, '');

          // Expand macro
          token = unMacrofy(token, prog.macros);

          if (token !== '')
            tokens.push(token);
        });

        return tokens;
      })(line);

      if (tokens[0].match(/^\./)) {
        // DIRECTIVE

        var directive = tokens.shift().replace(/^\./, '');

        switch (directive) {
        case 'dseg':
        case 'cseg':
          currentSegment = directive;
          break;
        case 'org':
          memoryCounter = requireUint(tokens[0]);
          break;
        case 'def':
          prog.macros[requireString(tokens[0])] = requireString(tokens[1]);
          break;
        case 'undef':
          delete prog.macros[requireString(tokens[0])];
          break;
        default:
          callback('Unrecognised directive "' + directive + '"');
        }

      } else {

        if (currentSegment === 'cseg') {
          // INSTRUCTION

          // Process instruction labels
          if (tokens[0].match(/:$/)) {
            // Add reference to labels table
            prog.labels[tokens.shift().replace(/:$/, '')] = memoryCounter;

            // Continue processing only if there are tokens remaining
            if (tokens.length < 1)
              continue;
          }

          // Add instruction to instructions map
          prog.instructions[memoryCounter] = tokens;
          memoryCounter++;
        } else if (currentSegment === 'dseg') {
          // DATA

          // Process memory labels
          if (tokens[0].match(/:$/) && tokens.length === 3) {
            var label = tokens[0].replace(/:$/, '');
            var size = (function(type) {
              switch (type) {
              case '.byte':
                return 0.25;
              case '.word':
                return 1;
              default:
                callback('Unrecognised data type "' + type + '"');
              }
            })(tokens[1]);
            var length = requireUint(tokens[2]);

            // Add reference in memory table
            prog.memory[tokens.shift().replace(/:$/, '')] = memoryCounter;
            memoryCounter += Math.ceil(size * length);

            // Continue processing only if there are tokens remaining
            if (tokens.length < 1)
              continue;
          } else
            callback('Failed to parse data segment token "' + tokens[0] + '"');

        }
      }
    }

    // Second pass, resolving memory and label names
    for (var i in prog.instructions) {
      var instruction = prog.instructions[i];

      for (var j in instruction) {
        var token = instruction[j];

        if (prog.memory[token] !== undefined)      // Memory
          instruction[j] = prog.memory[token];
        else if (prog.labels[token] !== undefined) // Label
          instruction[j] = prog.labels[token];
      }
    }

    return prog;
  };

  var prog2ram = function(prog, size) {

    var ram = new Array(prog.size);

    for (var i = 0; i < ram.length; i++) {
      // Lookup memory address in program
      if (prog.instructions[i] !== undefined) {
        ram[i] = (function(t) {
          switch (t[0]) {
          case 'nop':  return '00000000';
          case 'halt': return '01000000';
          case 'jmp':  return '02' + requireAddress(t[1]);
          case 'brts': return '03' + requireAddress(t[1]);
          case 'seto': return '04' + requireByte(t[1]) + requireByte(t[2]) + requireByte(t[3]);
          case 'tsti': return '05' + requireByte(t[1]) + requireByte(t[2]) + requireByte(t[3]);
          case 'call': return '06' + requireAddress(t[1]);
          case 'ret':  return '07000000';
          case 'reti': return '08000000';
          case 'sei':  return '09000000';
          case 'cli':  return '0A000000';
          case 'mtr':  return '0B' + requireReg(t[1]) + require16Address(t[2]);
          case 'rtm':  return '0C' + requireReg(t[1]) + require16Address(t[2]);
          case 'imtr': return '0D' + requireReg(t[1]) + requireReg(t[2]) + requireReg(t[3]);
          case 'rtim': return '0E' + requireReg(t[1]) + requireReg(t[2]) + requireReg(t[3]);
          case 'pshr': return '0F' + requireReg(t[1]) + '0000';
          case 'popr': return '10' + requireReg(t[1]) + '0000';
          case 'rtio': return '11' + requireByte(t[1]) + requireReg(t[2]) + '00';
          case 'iotr': return '12' + requireReg(t[1]) + requireByte(t[2]) + '00';
          case 'ldil': return '13' + requireReg(t[1]) + require16Address(t[2]);
          case 'ldih': return '14' + requireReg(t[1]) + require16Address(t[2]);
          case 'and':  return '15' + requireReg(t[1]) + requireReg(t[2]) + requireReg(t[3]);
          case 'or':   return '16' + requireReg(t[1]) + requireReg(t[2]) + requireReg(t[3]);
          case 'xor':  return '17' + requireReg(t[1]) + requireReg(t[2]) + requireReg(t[3]);
          case 'lsr':  return '18' + requireReg(t[1]) + requireReg(t[2]) + requireByte(t[3]);
          case 'lsl':  return '19' + requireReg(t[1]) + requireReg(t[2]) + requireByte(t[3]);

          default:     throw 'Unrecognised mnemonic "' + t[0] + '"';
          }
        })(prog.instructions[i]);
      } else {
        // Insert blank data
        ram[i] = int2hex32(0);
      }
    }

    return ram.join('\n');
  };

  try {
    callback(0, prog2ram(asm2prog(data.split('\n'))));
  } catch (err) {
    callback(err);
  }
};
