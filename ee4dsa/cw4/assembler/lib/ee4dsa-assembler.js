/*
 * data - String
 * options - Object
 *    annotate - Boolean, whether to generate annotated list
 *    size - Number
 *    idtSize - Number
 * callback - Function(err, data)
 */
module.exports = function(data, options, callback) {

  var u = require('./ee4dsa-util');

  /*
   * Pre-process the text by recursively expanding macro instructions.
   */
  var preProcess = function(text) {
    var processed = text
    // (Relative) Branch if equal
      .replace(/(r?)breq\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/,
              'equ $2 $3\n' +
              '$1brts $4')
    // (Relative) Branch if equal immediate
      .replace(/(r?)breqi\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/,
               'ldi __r $3\n' +
               'equ $2 __r\n' +
               '$1brts $4')
    // (Relative) Branch if not equal
      .replace(/(r?)brne\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/,
               'neq $2 $3\n' +
               '$1brts $4')
    // (Relative) Branch if not equal immediate
      .replace(/(r?)brnei\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/,
               'ldi __r $3\n' +
               'neq $2 __r\n' +
               '$1brts $4')
    // Load indirect to register
      .replace(/stdi\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/,
               'ldi __r $2\n' +
               'std $1 __r $3')
    // Store indirect to register
      .replace(/lddi\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/,
               'ldi __r $3\n' +
               'ldd $1 $2 __r')
    // Push immediate
      .replace(/pshi\s+([^\s]+)/,
               'ldi __r $1\n' +
               'pshr __r')
    // Load immediate
      .replace(/ldi\s+([^\s]+)\s+([^\s]+)/,
               'ldih $1 $2 >> 16\n' +
               'ldil $1 $2')
    // Equals immediate
      .replace(/eqi\s+([^\s]+)\s+([^\s]+)/,
               'ldi __r $2\n' +
               'equ $1 __r')
    // Not equals immediate
      .replace(/neqi\s+([^\s]+)\s+([^\s]+)/,
               'ldi __r $2\n' +
               'neq $1 __r')
    // Less than / Great than (or equal) (signed) immediate
      .replace(/(lt|gt)(e?)(s?)i\s+([^\s]+)\s+([^\s]+)/,
               'ldi __r $5\n' +
               '$1$2$3 $4 __r')
    // Add / Subtract (signed) immediate
      .replace(/(add|sub)(s?)i\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/,
               'ldi __r $5\n' +
               '$1$2 $3 $4 __r')

    if (processed !== text)
      return preProcess(processed);
    else
      return text;
  };

  var asm2prog = function(lines) {
    if (options.idtSize === undefined)
      options.idtSize = 8;

    var prog = {
      size: options.size || 4096,
      idt_size: options.idtSize,
      cseg: {},
      dseg: {},
      memory: {},
      labels: [],
      symbols: {},
      // Assembler context:
      memoryCounter: options.idtSize,
      currentSegment: 'cseg'
    };

    // Add built-in symbols:
    prog.symbols['ram_size'] = prog.size;
    prog.symbols['idt_size'] = prog.idt_size;
    prog.symbols['idt_start'] = 0;
    prog.symbols['prog_start'] = prog.idt_size;
    prog.symbols['__r'] = 'r4';
    prog.symbols['active_address'] = function(prog) {
      return prog.memoryCounter;
    };
    prog.symbols['active_segment'] = function(prog) {
      return prog.currentSegment;
    };
    prog.symbols['cseg_size'] = function(prog) {
      return u.len(prog.cseg);
    };
    prog.symbols['dseg_size'] = function(prog) {
      return u.len(prog.dseg);
    };

    // Populate empty interrupt descriptor table
    for (var i = 0; i < prog.idt_size; i++)
      prog.cseg[i] = ['reti'];

    // Iterate over lines
    for (var i in lines) {

      // Pre-process: trim comments & white space, lower case the text
      var line = lines[i].replace(/;.*/, '').trim().toLowerCase();

      // Skip empty lines
      if (line === '')
        continue;

      // Tokenize each line
      var tokens = u.tokenize(line, [prog.symbols, prog.labels, prog.memory], prog);

      if (tokens[0].match(/^\./)) {
        // DIRECTIVE

        var directive = tokens.shift().replace(/^\./, '');

        switch (directive) {
        case 'dseg':
        case 'cseg':
          prog.currentSegment = directive;
          break;
        case 'org':
          prog.memoryCounter = u.requireUint(tokens[0]);
          break;
        case 'isr':
          prog.cseg[u.requireUint(tokens[0])] = ['jmp', tokens[1]];
          break;
        case 'def':
          prog.symbols[u.requireString(tokens[0])] = u.requireString(tokens[1]);
          break;
        case 'defp':
          if (prog.symbols[u.requireString(tokens[0])] === undefined)
            prog.symbols[u.requireString(tokens[0])] = u.requireString(tokens[1]);
          break;
        case 'undef':
          delete prog.symbols[u.requireString(tokens[0])];
          break;
        default:
          throw 'Unrecognised directive "' + directive + '"';
        }

        // Exit directive. This can't be in the switch since 'break'
        // has special meaning within switches.
        if (directive === 'exit')
          break;

      } else {

        if (prog.currentSegment === 'cseg') {
          // INSTRUCTION

          // Process instruction labels
          if (tokens[0].match(/:$/)) {
            var label = tokens.shift().replace(/:$/, '');

            // If label is a numerical address, then we have already
            // defined the label, so perform a reverse lookup from
            // within the labels table:
            if (!isNaN(new Number(label)))
              label = (function (address) {
                for (var l in prog.labels)
                  if (prog.labels[l] == label)
                    return l;

                throw 'Invalid label name "' + label + '"';
              })(label);

            // Add reference to labels table
            prog.labels[label] = prog.memoryCounter;

            // Continue processing only if there are tokens remaining
            if (tokens.length < 1)
              continue;
          }

          // Add instruction to instructions map
          prog.cseg[prog.memoryCounter] = tokens;
          prog.memoryCounter++;
        } else if (prog.currentSegment === 'dseg') {
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
                throw 'Unrecognised data type "' + type + '"';
              }
            })(tokens[1]);
            var length = u.requireUint(tokens[2]);
            var label = tokens.shift().replace(/:$/, '');
            var dstart = prog.memoryCounter, dend = dstart + Math.ceil(size * length);

            // Add reference in memory table and populate dseg
            prog.memory[label] = dstart;
            for (var i = dstart; i < dend; i++) {
              prog.dseg[i] = label;

              if (dend - dstart > 1)
                prog.dseg[i] += '[' + (i - dstart) + ']';
            }

            // Update memory counter
            prog.memoryCounter = dend;

            // Continue processing only if there are tokens remaining
            if (tokens.length < 1)
              continue;
          } else
            throw 'Failed to parse data segment token "' + tokens[0] + '"';

        }
      }
    }

    // Resolve memory and label names in instructions
    for (var i in prog.cseg) {
      var instruction = prog.cseg[i];

      for (var j in instruction) {
        var token = instruction[j];

        if (prog.memory[token] !== undefined)      // Memory
          instruction[j] = prog.memory[token];
        else if (prog.labels[token] !== undefined) // Label
          instruction[j] = prog.labels[token];
      }
    }

    // Write metadata
    prog.cseg_size = u.len(prog.cseg);
    prog.cseg_util = prog.cseg_size / prog.size;
    prog.dseg_size = u.len(prog.dseg);
    prog.dseg_util = prog.dseg_size / prog.size;
    prog.util = prog.cseg_util + prog.dseg_util;

    return prog;
  };

  /*
   * Generate a program listing
   */
  var prog2list = function(prog) {
    var list = [];

    // Iterate over objects in prog
    for (var i in prog) {
      var s = '.' + i.toUpperCase();    // Begin with property name

      if (typeof prog[i] == 'object') { // Property array value
        var p = [];
        s += '\n';
        for (var j in prog[i]) {        // Property -> Value pair
          if (typeof prog[i][j].join === 'function')
            p.push('        ' + j + ' = ' + prog[i][j].join(' '));
          else
            p.push('        ' + j + ' = ' + prog[i][j]);
        }
        s += p.join('\n');
      } else                            // Property value
        s += ' = ' + prog[i];

      list.push(s + '\n');              // Add property string to list
    };

    return list.join('\n');
  };

  var prog2ram = function(prog) {

    var ram = new Array(prog.size);

    for (var i = 0; i < ram.length; i++) {
      // Lookup memory address in program
      if (prog.cseg[i] !== undefined) {
        try {
          ram[i] = (function(t) {
            switch (t[0]) {
            case 'nop':   return '00000000';
            case 'halt':  return '01000000';
            case 'jmp':   return '02' + u.requireAddress(t[1]);
            case 'rjmp':  return '02' + (u.requireAddress(eval(i + u.requireInt(t[1]))));
            case 'brts':  return '03' + u.requireAddress(t[1]);
            case 'rbrts': return '03' + (u.requireAddress(eval(i + u.requireInt(t[1]))));
            case 'seto':  return '04' + u.requireByte(t[1]) + u.requireByte(t[2]) + u.requireByte(t[3]);
            case 'tsti':  return '05' + u.requireByte(t[1]) + u.requireByte(t[2]) + u.requireByte(t[3]);
            case 'call':  return '06' + u.requireAddress(t[1]);
            case 'rcall': return '06' + (u.requireAddress(eval(i + u.requireInt(t[1]))));
            case 'ret':   return '07000000';
            case 'reti':  return '08000000';
            case 'sei':   return '09000000';
            case 'cli':   return '0A000000';
            case 'ld':    return '0B' + u.requireReg(t[1]) + u.require16Address(t[2]);
            case 'st':    return '0C' + u.requireReg(t[1]) + u.require16Address(t[2]);
            case 'ldd':   return '0D' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireReg(t[3]);
            case 'std':   return '0E' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireReg(t[3]);
            case 'pshr':  return '0F' + u.requireReg(t[1]) + '0000';
            case 'popr':  return '10' + u.requireReg(t[1]) + '0000';
            case 'stio':  return '11' + u.requireByte(t[1]) + u.requireReg(t[2]) + '00';
            case 'ldio':  return '12' + u.requireReg(t[1]) + u.requireByte(t[2]) + '00';
            case 'ldil':  return '13' + u.requireReg(t[1]) + u.require16Address(t[2]);
            case 'ldih':  return '14' + u.requireReg(t[1]) + u.require16Address(t[2]);
            case 'and':   return '15' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireReg(t[3]);
            case 'or':    return '16' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireReg(t[3]);
            case 'xor':   return '17' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireReg(t[3]);
            case 'lsr':   return '18' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireByte(t[3]);
            case 'lsl':   return '19' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireByte(t[3]);
            case 'equ':   return '1A00' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'neq':   return '1A01' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'lt':    return '1A02' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'lts':   return '1B02' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'lte':   return '1A03' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'ltes':  return '1B03' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'gt':    return '1A04' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'gts':   return '1B04' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'gte':   return '1A05' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'gtes':  return '1B05' + u.requireReg(t[1]) + u.requireReg(t[2]);
            case 'eqz':   return '1A06' + u.requireReg(t[1]) + '00';
            case 'nez':   return '1A07' + u.requireReg(t[1]) + '00';
            case 'mov':   return '20' + u.requireReg(t[1]) + u.requireReg(t[2]) + '00';
            case 'clr':   return '20' + u.requireReg(t[1]) + '0000';
            case 'neg':   return '22' + u.requireReg(t[1]) + u.requireReg(t[1]) + '00'
            case 'inc':   return '21' + u.requireReg(t[1]) + u.requireReg(t[1]) + '00';
            case 'incs':  return '29' + u.requireReg(t[1]) + u.requireReg(t[1]) + '00';
            case 'dec':   return '22' + u.requireReg(t[1]) + u.requireReg(t[1]) + u.requireReg(t[1]);
            case 'decs':  return '2A' + u.requireReg(t[1]) + u.requireReg(t[1]) + u.requireReg(t[1]);
            case 'add':   return '20' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireReg(t[3]);
            case 'adds':   return '28' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireReg(t[3]);
            case 'sub':   return '23' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireReg(t[3]);
            case 'subs':  return '2B' + u.requireReg(t[1]) + u.requireReg(t[2]) + u.requireReg(t[3]);

            default:     throw 'Unrecognised mnemonic "' + t[0] + '"';
            }
          })(prog.cseg[i]);
        } catch (err) {
          throw 'Address ' + i + ', Instruction: "' +
            prog.cseg[i].join(' ') + '", Error: ' + err
        }
      } else {
        // Insert blank data
        ram[i] = u.int2hex(0, 8);
      }

      // Annotate the listing if required
      if (options.annotate) {
        ram[i] += ' -- ' + i;
        if (prog.cseg[i])
          ram[i] += ' ' + prog.cseg[i].join(' ');
        if (prog.dseg[i])
          ram[i] += ' DATA: ' + prog.dseg[i];
      }
    }

    return ram.join('\n');
  };

  try {
    // Pre-process:
    var source = preProcess(data);

    // First pass:
    var prog = asm2prog(source.split('\n'));

    // Second pass:
    callback(0, { prog: prog, ram: prog2ram(prog), list: prog2list(prog) });
  } catch (err) {
    callback(err);
  }
};
