$(document).ready(function() {
  $(".status").click(function(e) {
    var staff_id = $(this).parents('tr').attr('id');
    $.ajax({
      type: "POST",
      url: "/status",
      data: { id: staff_id },     
      }).done(function(data) {
        if(data.status == 'Out') {
          $("#" + data.id + " i").removeClass('icon-ok').addClass('icon-remove')
          $("#" + data.id + " a.status").text('Sign In')
          $("#" + data.id).removeClass('success').addClass('error');
        }
        else {
          $("#" + data.id + " i").removeClass('icon-remove').addClass('icon-ok')
          $("#" + data.id + " a.status").text('Sign Out')
          $("#" + data.id).removeClass('error').addClass('success');
        }
    });
    e.preventDefault();
  });
});