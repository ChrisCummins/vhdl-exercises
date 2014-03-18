#!/usr/bin/env node

var lazy = require('lazy');
var fs  = require('fs');
var path = require('path');
var u = require('./lib/ee4dsa-util');
var assemble = require('./lib/ee4dsa-assembler');

var argv = require('optimist')
    .usage('Usage: $0 -s <path> [options]')
    .wrap(80)
    .demand('source')
    .option('source', {
      alias: 's',
      desc: 'Input source file'
    })
    .option('output', {
      alias: 'o',
      default: '<source>.o',
      desc: 'Output RAM file path'
    })
    .option('list', {
      alias: 'l',
      default: '<source>.l',
      desc: 'Output listing file path'
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
      desc: 'Annotate the generated RAM file'
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
  if (!argv.source.match(/\.s$/i))
    throw 'Source must have ".s" extension'

  /* Generate default paths for output files */
  if (argv.output === '<source>.o')
    argv.output = argv.source.replace(/\.s$/, '.o');
  if (argv.list === '<source>.l')
    argv.list = argv.source.replace(/\.s$/, '.l');

  /* Assemble input file(s) */
  assemble(readAsmFile(argv.source), {
    size: argv['ram-size'],
    idtSize: argv['idt-size'],
    annotate: argv.annotate
  }, function(err, data) {
    if (err)
      throw err;

    /* Write output files */
    fs.writeFile(argv.output, data.ram);
    fs.writeFile(argv.list, data.list);

    /* Print summary */
    console.log(path.basename(argv.source) +
                ': ' + (data.prog.cseg_size + data.prog.dseg_size) + ' words, ' +
                u.perc(data.prog.util) + ' util ' +
                '(cseg: ' + u.perc(data.prog.cseg_util / data.prog.util) +
                ' dseg: ' + u.perc(data.prog.dseg_util / data.prog.util) + ')');
  });
} catch (err) {
  process.stderr.write('fatal: ' + err.toString() + '\n');
  process.exit(2);
}