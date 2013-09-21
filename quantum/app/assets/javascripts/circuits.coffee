//= require vendor/kinetic
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
  return getOperatorByIdType(operatorId, operatorType())

getOperatorByIdType = (id, type) ->
  operators = GATES
  operators = MEASUREMENTS if type == 'measurement'
  operators = CONTROLLED_GATES if type == 'controlled'
  return _.find(operators, (op) -> op.id == id)

deleteOperatorClick = ->
  mousePos = @stage.getMousePosition()
  op = @operators.findClosest(mousePos['x'], mousePos['y'])
  @operators.remove op, @operatorsLayer, true

moveOperatorClick = ->
  mousePos = @stage.getMousePosition()
  op = @operators.findClosest(mousePos['x'], mousePos['y'])
  $(@stage.getContent()).off('click.normal')
  $(@stage.getContent()).on('mousemove', =>
    mousePos = @stage.getMousePosition()
    [lineIds, y] = findLinesY(mousePos['y'], op.size)
    op.changePosition(mousePos['x'], y)
    op.changeLines(lineIds)
    @operatorsLayer.draw()
  )
  $(@stage.getContent()).on('click.move', =>
    $(@stage.getContent()).off('mousemove')
    $(@stage.getContent()).off('click.move')
    bindStageClick()
  )

findLinesY = (y, operatorSize) ->
  lines = @lines.findClosestByY(y, operatorSize)
  lineIds = _.map(lines, (line) -> line.id)
  # Average of all ys of lines
  y = _.reduce(_.map(lines, (line) -> line.y), ((m, n) -> m + n), 0) / lines.length

  return [lineIds, y]

inspectClick = ->
  mousePos = @stage.getMousePosition()

  op = @operators.leftOf(mousePos['x']).findClosestByX(mousePos['x'])
  oId = -1
  oId = op.id if op?

  showResults(oId)

  # o = after operator o

showResults = (oId) ->
  results = @resultsData[oId]
  html = "<ul>"
  
  _.each(results, (state) ->
    html += "<li>"
    html += "<img src='/latex/qcircuit/" + state['stateLatex'] + ".png?height=30'>"
    html += " w.p. "
    html += "<img src='/latex/math/" + state['probabilityLatex'] + ".png?height=30'>"
    html += "</li>"
  )
  html += "</ul>"
  $("#results").html(html)


newOperatorClick = =>
  mousePos = @stage.getMousePosition()
  operator = getOperator()

  [lineIds, y] = findLinesY(mousePos['y'], operator.size)
  op = newOperator(lineIds, mousePos['x'], y, operator)

  if operator.type == "controlled"
    # jquery .one not working in this situation
    $(@stage.getContent()).off('click.normal')
    $(@stage.getContent()).on('click.controlled', =>
      $(@stage.getContent()).off('click.controlled')
      bindStageClick()

      newMousePos = @stage.getMousePosition()
      measurement = @operators.findAllByType('measurement').findClosest(newMousePos['x'], newMousePos['y'])
      op.measurement = measurement
      op.renderMeasurementConnection(@operatorsLayer, true)
    )

setMode = (mode) ->
  $("#controlLinks > li > a").removeClass("active")
  $("#controlLinks > li > #" + mode).addClass("active")
  @mode = mode
  run() if mode == "run"

getMode = ->
  return @mode

stageClick = ->
  switch getMode()
    when "add" then newOperatorClick()
    when "move" then moveOperatorClick()
    when "delete" then deleteOperatorClick()
    when "run" then inspectClick()

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

bindStageClick = ->
  $(@stage.getContent()).on('click.normal', stageClick)

addLine = ->
  line = @lines.new()
  line.render(@linesLayer, true)

deleteLine = ->
  line = @lines.removeLast @linesLayer, true
  return unless line?
  @operators.removeWhere((op) ->
    return _.contains(op.lines, line.id)
  , @operatorsLayer, true)

bindLinkClick = ->
  $('#add').on('click', -> setMode('add'); return false)
  $('#move').on('click', -> setMode('move'); return false)
  $('#delete').on('click', -> setMode('delete'); return false)
  $('#run').on('click', -> setMode('run'); return false)
  $('#save').on('click', -> save(); return false)
  $('#addLine').on('click', -> addLine(); return false)
  $('#deleteLine').on('click', -> deleteLine(); return false)

# Initialises the page with a new stage
init = ->
  setupDropdowns()
  setMode('add')
  @stage = newStage('canvasContainer')
  bindStageClick()
  bindLinkClick()

  @linesLayer = newLayer(@stage)
  @lines = new Collection(Line)

  @operatorsLayer = newLayer(@stage)
  @operators = new Collection(Operator)

  if existingCircuit()
    loadCircuit()
  else
    setupNewCircuit()

setupNewCircuit = ->
  @lines.add(3)
  @lines.render(@linesLayer)

existingCircuit = ->
  parts = window.location.pathname.split(".")[0].split("/")
  return parts[parts.length - 3] == "circuits"

dataPath = (infix) ->
  infix = "" unless infix?
  basePath = window.location.pathname.split(".")[0]
  return basePath + infix + ".json"

loadCircuit = ->
  $.get(dataPath()).done((data) =>
    renderCircuit(data['circuit'])
  )

renderCircuit = (circuit) =>
  $('#save').text('Update')
  @lines.add(circuit['lines'])
  @lines.render(linesLayer)

  # We need to add controlled gates seperately
  otherOps = _.reject(circuit['operators'], (h) -> h['operatorType'] == 'controlled')
  controlledOps = _.filter(circuit['operators'], (h) -> h['operatorType'] == 'controlled')

  @operators.addFromArrays(_.map(otherOps, (h) ->
    op = getOperatorByIdType(h['operatorId'], h['operatorType'])
    return [h['id'], h['lines'], h['x'], h['y'], h['operatorType'], h['operatorId'], op.symbol, op.size]
  ))
  @operators.addFromArrays(_.map(controlledOps, (h) ->
    op = getOperatorByIdType(h['operatorId'], h['operatorType'])
    measurement = @operators.findAllByType('measurement').findById(h['measurementId'])
    return [h['id'], h['lines'], h['x'], h['y'], h['operatorType'], h['operatorId'], op.symbol, op.size, measurement]
  ))
  @operators.render(@operatorsLayer)

genHash = ->
  operators = @operators.toArray()
  hash = {
    operators: operators
    lines: @lines.count()
  }
  return hash

save = ->
  $.ajax(
    url: dataPath()
    type: 'PUT'
    data: {circuit: JSON.stringify(genHash())}
  ).done((data) ->
    window.location.href = data['url'] if data['status'] == 'successful'
  )
  # $.post('http://localhost:5000/save', JSON.stringify(genHash())).done((data) ->
  # console.log(data['status'])
  # )

run = ->
  # TODO Is this RESTul?
  $.post('/circuits/run', {circuit: JSON.stringify(genHash())}).done((data) =>
    @resultsData = data['results']
    #     html = "<ul>"
    # 
    #     _.each(data['results'], (state) ->
    #       # CamelCase?
    #       # html += "<li><img src='" + state['state_latex'] + "'> w.p. " + state['probability_string'] + "</li>"
    #       # html += "<li>" + state['state_string'] + " w.p. " + state['probability_string'] + "</li>"
    #       html += "<li>"
    #       html += "<img src='/latex/qcircuit/" + state['state_latex'] + ".png?height=30'>"
    #       html += " w.p. "
    #       html += "<img src='/latex/math/" + state['probability_latex'] + ".png?height=30'>"
    #       html += "</li>"
    #     )
    #     html += "</ul>"
    #     $("#results").html(html)
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

  resize()
  init()
