#!/usr/bin/env node

var lazy = require('lazy');
var fs  = require('fs');
var path = require('path');
var u = require('./lib/ee4dsa-util');
var assemble = require('./lib/ee4dsa-assembler');

var argv = require('optimist')
    .usage('Usage: $0 <assembly source>')
    .wrap(80)
    .demand('source')
    .option('source', {
      alias: 's',
      desc: 'Input source file'
    })
    .option('output', {
      alias: 'o',
      default: 'a.out',
      desc: 'Output RAM file'
    })
    .option('ram-size', {
      alias: 'r',
      default: 4096,
      desc: 'Set the size of the output RAM'
    })
    .option('idt-size', {
      alias: 'i',
      default: 8,
      desc: 'Set the size of the IDT'
    })
    .option('annotate', {
      alias: 'a',
      default: false,
      desc: 'Annotate the generated RAM'
    }).argv;

/*
 * Open and read an input file, returning its contents. Operates
 * recursively on .input directives.
 */
var readAsmFile = function(file) {
  var lines = fs.readFileSync(file).toString().split('\n');

  /* Nest '.include' directives */
  for (var i in lines) {
    var match = lines[i].match(/^([ 	]+)?\.include "(.*)"([ 	]+)?$/);

    if (match) {
      lines[i] = readAsmFile(path.dirname(file) + '/' + match[2]);
    }
  }

  return u.flatten(lines).join('\n');
};

try {
  /* Assemble input file(s) */
  assemble(readAsmFile(argv.source), {
    size: argv['ram-size'],
    idtSize: argv['idt-size'],
    annotate: argv.annotate
  }, function(err, data) {
    if (err) {
      process.stderr.write('fatal: ' + err + '\n');
      process.exit(2);
    }

    /* Write assembled output to file */
    fs.writeFile(argv.output, data, function(err) {
      if (err) {
        process.stderr.write('Unable to write file "' + argv.output + '"\n');
        process.exit(3);
      }
    });
  });
} catch (err) {
  process.stderr.write(err.toString() + '\n');
  process.exit(2);
}
