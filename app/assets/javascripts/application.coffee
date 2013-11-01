//= require vendor/jquery
//= require vendor/jquery_ujs
//= require vendor/bootstrap

showOpenId = ->
  $('#openIdModal').show()

closeOpenId = ->
  $('#openIdModal').hide()

setupOpenId = ->
  $('.closeOpenId').on('click', -> closeOpenId())
  $('#openIdOpen').on('click', -> showOpenId())

$(document).ready ->
  setupOpenId()

  $(document).on('click', 'a.close', (e) ->
    e.preventDefault()
    $(@).parent().slideUp('slow', ->
      $(@).remove()
    )
  )
