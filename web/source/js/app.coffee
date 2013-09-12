//= require vendor/kinetic-v4.6.0.min
//= require vendor/underscore
//= require Collection
//= require Line
//= require Operator

GATES = [{'id': 1, 'name': 'Hadamard', 'symbol': 'H'}, {'id': 2, 'name': 'CNOT', 'symbol': 'CNOT'}, {'id': 3, 'name': 'Pauli Z', 'symbol': 'Z'}]
MEASUREMENTS = [{'id': 1, 'name': 'Standard Measurement', 'symbol': 'M'}]

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

newOperatorClick = =>
  mousePos = @stage.getMousePosition()
  line = @lines.findClosestByY(mousePos['y'])
  newOperator(line.id, mousePos['x'], line.y)

newOperator = (lineId, x, y) ->
  operatorType = $('#operatorType').val()
  operatorId = parseInt($('#operatorId').val())

  operators = GATES
  operators = MEASUREMENTS if operatorType == 'measurement'
  operator = _.find(operators, (op) -> op.id == operatorId)

  op = @operators.new(lineId, x, y, operatorType, operatorId, operator.symbol)
  op.render(operatorsLayer, true)

setupDropdowns = ->
  $('#operatorType').on('change', ->
    changeDropdown($(@).val())
  )
  changeDropdown('gate')

changeDropdown = (operatorType) ->
  operators = GATES
  operators = MEASUREMENTS if operatorType == 'measurement'

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
    )
  )


window.run = run

init()
