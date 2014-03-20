var u = require('./lib/ee4dsa-util');
var assemble = require('./lib/ee4dsa-assembler');

// HTML elements
var $code = $('#code');
var $errors = $('#errors');
var $outputRam = $('#output-ram');
var $outputList = $('#output-list');

// Internal state
var _ramSize = 1024
var _idtSize = 8;
var _annotate = true;

// Add a new visible error
var addError = function(msg) {
  $errors.append("<div class=\"alert alert-error\">" + msg +
                 "<a class=\"close\" data-dismiss=\"alert\" " +
                 "href=\"#\">&times;</a></div>");
};

// Add a new visible error
var addMessage = function(msg) {
  $errors.append("<div class=\"alert alert-success\">" + msg +
                 "<a class=\"close\" data-dismiss=\"alert\" " +
                 "href=\"#\">&times;</a></div>");
};

var updateView = function() { // Display errors
  $errors.html('');
  $outputRam.text('');
  $outputList.text('');

  assemble($code.val(), {
    size: _ramSize,
    idtSize: _idtSize,
    annotate: _annotate
  }, function(err, data) {
    if (err) // Show errors
      addError(err);
    else if (data.prog.cseg_size + data.prog.dseg_size > data.prog.idt_size)
      addMessage('Assembled ' + (data.prog.cseg_size + data.prog.dseg_size) +
                 ' words, ' + u.perc(data.prog.util, 3) + ' util ' +
                 '(cseg: ' + u.perc(data.prog.cseg_util / data.prog.util, 0) +
                 ' dseg: ' + u.perc(data.prog.dseg_util / data.prog.util, 0) +
                 ')');

    $outputRam.text(data.ram);
    $outputList.text(data.list);
    }
  });
};

// Update as the user types
$code.bind('input propertychange', function() {
  updateView();
});

$('#ram-size').change(function() {
  _ramSize = parseInt($('#ram-size option:selected').val());
  updateView();
});


$('#idt-size').change(function() {
  _idtSize = parseInt($('#idt-size option:selected').val());
  updateView();
});

$('#annotate').change(function() {
  _annotate = parseInt($('#annotate option:selected').val());
  updateView();
});

updateView();
