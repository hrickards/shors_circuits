//= require vendor/kinetic-v4.6.0.min
//= require vendor/underscore
//= require Collection
//= require Line
//= require Operator

GATES = [{'id': 1, 'name': 'Hadamard', 'symbol': 'H', 'size': 1, 'type': 'gate'}, {'id': 2, 'name': 'CNOT', 'symbol': 'CNOT', 'size': 2, 'type': 'gate'}, {'id': 3, 'name': 'Pauli Z', 'symbol': 'Z', 'size': 1, 'type': 'gate'}]
MEASUREMENTS = [{'id': 1, 'name': 'Standard Measurement', 'symbol': 'M', 'size': 1, 'type': 'measurement'}]
CONTROLLED_GATES = [{'id': 1, 'name': 'Controlled G', 'symbol': 'G', 'size': 1, 'type': 'controlled'}]

# Returns new canvas stage for passed canvas ID
newStage = (canvasId) ->
  canvasWidth = $('#' + canvasId).width()
  canvasHeight = $('#' + canvasId).height()
  stage = new Kinetic.Stage
    container: canvasId
    width: canvasWidth
    height: canvasHeight
  window.stage = stage

  return stage

newLayer = (stage) ->
  layer = new Kinetic.Layer()
  stage.add(layer)
  return layer

operatorType = ->
  return $('#operatorType').val()

getOperator = ->
  operatorId = parseInt($('#operatorId').val())

  operators = GATES
  operators = MEASUREMENTS if operatorType() == 'measurement'
  operators = CONTROLLED_GATES if operatorType() == 'controlled'
  return _.find(operators, (op) -> op.id == operatorId)

newOperatorClick = =>
  mousePos = @stage.getMousePosition()
  operator = getOperator()

  lines = @lines.findClosestByY(mousePos['y'], operator.size)
  lineIds = _.map(lines, (line) -> line.id)
  # Average of all ys of lines
  y = _.reduce(_.map(lines, (line) -> line.y), ((m, n) -> m + n), 0) / lines.length

  op = newOperator(lineIds, mousePos['x'], y, operator)

  if operator.type == "controlled"
    # jquery .one not working in this situation
    $(@stage.getContent()).off('click.normal');
    $(@stage.getContent()).on('click.controlled', =>
      $(@stage.getContent()).off('click.controlled')
      $(@stage.getContent()).on('click.normal', newOperatorClick)

      newMousePos = @stage.getMousePosition()
      measurement = @operators.findAllByType('measurement').findClosest(newMousePos['x'], newMousePos['y'])
      op.measurement = measurement
      op.renderMeasurementConnection(@operatorsLayer, true)
    )

newOperator = (lines, x, y, operator) ->
  op = @operators.new(lines, x, y, operator.type, operator.id, operator.symbol, operator.size)
  op.render(@operatorsLayer, true)
  return op

setupDropdowns = ->
  $('#operatorType').on('change', ->
    changeDropdown($(@).val())
  )
  changeDropdown('gate')

changeDropdown = (opType) ->
  operators = GATES
  operators = MEASUREMENTS if opType == 'measurement'
  operators = CONTROLLED_GATES if operatorType() == 'controlled'

  $('#operatorId').empty()
  _.each(operators, (operator) ->
    $('#operatorId').append($("<option></option>").attr("value", operator.id).text(operator.name))
  )

# Initialises the page with a new stage
init = ->
  setupDropdowns()
  @stage = newStage('canvasContainer')
  $(@stage.getContent()).on('click.normal', newOperatorClick)

  @linesLayer = newLayer(@stage)
  @lines = new Collection(Line)
  @lines.add(3)
  @lines.render(linesLayer)

  @operatorsLayer = newLayer(@stage)
  @operators = new Collection(Operator)

genHash = ->
  operators = @operators.toHash()
  hash = {
    operators: operators
    lines: @lines.count()
  }
  return hash

run = ->
  console.log(genHash())
  $.post('http://localhost:5000', JSON.stringify(genHash())).done((data) ->
    states = data['results']
    html = "<ul>"
    _.each(states, (state) ->
      html += "<li><img src='" + state['stateLatex'] + "'> w.p. " + state['probabilityString'] + "</li>"
    )
    html += "</ul>"
    $("#results").html(html)
  )

resize = ->
  $("#sidebar").height($("#page").height() - $("#header").height())
  $("#canvasContainer").height($("#page").height() - $("#header").height())

  if @stage?
    canvasWidth = $('#canvasContainer').width()
    canvasHeight = $('#canvasContainer').height()
    @stage.setWidth(canvasWidth)
    @stage.setHeight(canvasHeight)

$(document).ready ->
  $(window).resize( ->
    clearTimeout(@resizeTO) if @resizeTO
    @resizeTO = setTimeout( ->
      $(window).trigger('resizeEnd')
    , 50)
  )

  $(window).on('resizeEnd orientationchange', resize)
  $('#run').on('click', run)

  resize()
  init()
