//= require vendor/kinetic-v4.6.0.min
//= require vendor/underscore
//= require Collection
//= require Line
//= require Operator

GATES = [{'id': 1, 'name': 'Hadamard', 'symbol': 'H', 'size': 1}, {'id': 2, 'name': 'CNOT', 'symbol': 'CNOT', 'size': 2}, {'id': 3, 'name': 'Pauli Z', 'symbol': 'Z', 'size': 1}]
MEASUREMENTS = [{'id': 1, 'name': 'Standard Measurement', 'symbol': 'M', 'size': 1}]

# Returns new canvas stage for passed canvas ID
newStage = (canvasId) ->
  canvasWidth = $('#' + canvasId).width()
  canvasHeight = 600
  stage = new Kinetic.Stage
    container: canvasId
    width: canvasWidth
    height: canvasHeight

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
  return _.find(operators, (op) -> op.id == operatorId)

newOperatorClick = =>
  mousePos = @stage.getMousePosition()
  operator = getOperator()

  lines = @lines.findClosestByY(mousePos['y'], operator.size)
  # Average of all ys of lines
  y = _.reduce(_.map(lines, (line) -> line.y), ((m, n) -> m + n), 0) / lines.length
  newOperator(_.map(lines, (line) -> line.id), mousePos['x'], y, operator)

newOperator = (lines, x, y, operator) ->
  op = @operators.new(lines, x, y, operatorType(), operator.id, operator.symbol, operator.size)
  op.render(operatorsLayer, true)

setupDropdowns = ->
  $('#operatorType').on('change', ->
    changeDropdown($(@).val())
  )
  changeDropdown('gate')

changeDropdown = (opType) ->
  operators = GATES
  operators = MEASUREMENTS if opType == 'measurement'

  $('#operatorId').empty()
  _.each(operators, (operator) ->
    $('#operatorId').append($("<option></option>").attr("value", operator.id).text(operator.name))
  )

# Initialises the page with a new stage
init = ->
  setupDropdowns()
  @stage = newStage('canvasContainer')
  $(@stage.getContent()).on('click', newOperatorClick)

  @linesLayer = newLayer(@stage)
  @lines = new Collection(Line)
  @lines.add(2)
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
  $.post('http://localhost:5000', JSON.stringify(genHash())).done((data) ->
    states = data['results']
    _.each(states, (state) ->
      console.log(state['stateString'] + " w.p. " + state['probabilityString'])
      console.log(state['stateLatex'])
    )
  )


window.run = run

init()
