$(document).ready(function () {
  var checkbox = $('#autoreload'),
      domain = $('#domain');

  if (location.hash == '#autoreload') {
    checkbox.prop('checked', true);
  }

  setInterval(function () {
    if (location.hash == '#autoreload' && !domain.is(":focus")) {
      location.reload();
    }
  }, 3000);

  checkbox.on('change', function (e) {
    if ($(this).is(":checked")) {
      location.hash = '#autoreload'
    } else {
      location.hash = ''
    }
  });
});