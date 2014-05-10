$(document).ready(function() {
  $('p.toggle').siblings('ul').hide();
  $('p.toggle').click(function () {
    $(this).siblings('ul').slideToggle();
    $(this).find('a').toggleClass('fold');
  });
  var page_id = $('body').attr('id');
  var current_item = $('#nav_'+page_id+' a');
  current_item.parentsUntil('ul.nav', 'ul').each(function () {
    $(this).toggle();
  });
  current_item.parentsUntil('ul.nav', 'li').each(function () {
  $(this).find('> p a').toggleClass('fold');
  });
  current_item.css('color', '#f93');
});
