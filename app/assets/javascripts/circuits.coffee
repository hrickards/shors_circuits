# jquery globally
//= require vendor/jquery-ui
//= require vendor/kinetic
//= require vendor/underscore
//= require vendor/raphael
//= require vendor/g.raphael
//= require vendor/g.pie
//= require Collection
//= require Line
//= require Operator
//= require VerticalLine
//= require MatrixInput

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
  operatorId = $('#operatorId').val()
  return getOperatorByIdType(operatorId, operatorType())

getOperatorByIdType = (id, type) ->
  operators = window.GATES
  operators = window.MEASUREMENTS if type == 'measurement'
  operators = window.CONTROLLED_GATES if type == 'controlled'
  return _.find(operators, (op) -> op.id == id)

deleteOperatorClick = ->
  mousePos = @stage.getMousePosition()
  op = @operators.findClosest(mousePos['x'], mousePos['y'])

  if op.operatorType == 'measurement'
    connectedControlled = @operators.findAllByType('controlled').filter((controlled) -> controlled.measurement == op)
    _.map(connectedControlled, (controlled) -> @operators.remove controlled)

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
    if op.operatorType == 'measurement'
      connectedControlled = @operators.findAllByType('controlled').filter((controlled) -> controlled.measurement == op)
      _.map(connectedControlled, (controlled) -> controlled.moveMeasurementConnection())
      
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

ensureVerticalLineAt = (x) ->
  if @verticalLine?
    @verticalLine.changePosition(x)
    @inspectorsLayer.draw()
  else
    @verticalLine = new VerticalLine(x)
    @verticalLine.render(@inspectorsLayer, true)

ensureNoVerticalLine = ->
  if @verticalLine?
    @verticalLine.unrender(@inspectorsLayer, true)
    @verticalLine = undefined

highlightMeasurement = (opm) ->
  opm.highlight()
  @operatorsLayer.draw()

unhighlightAllMeasurements = ->
  _.each(@operators.findAllByType('measurement').models, (op) ->
    op.unhighlight()
  )
  @operatorsLayer.draw()

inspectClick = ->
  $("#inspectMessage").hide()
  mousePos = @stage.getMousePosition()
  ensureVerticalLineAt(mousePos['x'])

  op = @operators.leftOf(mousePos['x']).findClosestByX(mousePos['x'])
  oId = -1
  oId = op.id if op?
  showResults(oId)

  # Find closest measurement
  unhighlightAllMeasurements()
  opm = @operators.findAllByType('measurement').findClosestByX(mousePos['x'])
  if opm?
    highlightMeasurement(opm)
    showMeasurementResults(opm.id) unless @oldOpmId == opm.id
    @oldOpmId = opm.id

showResults = (oId) ->
  results = @resultsData[oId]
  html = "<ul>"
  
  _.each(results, (state) ->
    html += "<li>"
    html += "<img src='/latex/qcircuit/" + state['state_latex'] + ".png?height=30'>"
    html += " w.p. "
    html += "<img src='/latex/math/" + state['probability_latex'] + ".png?height=30'>"
    html += "</li>"
  )
  html += "</ul>"
  $("#results").html(html)

removeResults = ->
  $("#results").html("")

showMeasurementResults = (oId) ->
  results = @measurementResultsData[oId]
  keys = _.keys(results)
  labels = _.map(keys, (key) -> key + " wp %%")
  values = _.map(keys, (key) -> results[key])

  unless @r?
    cont = $('#measurementsContainer')
    @r = Raphael(cont.get(0), cont.width(), cont.height())

  @r.clear()
  @pie = @r.piechart(
    @r.width/2,
    140,
    100,
    values,
    {
      legend: labels
      legendpos: "east"
    }
  )

  @r.text(@r.width/2, 15, "Measurement Result").attr({ font: "20px sans-serif" })

  @pie.hover( ->
    @sector.stop()
    @sector.scale(1.03, 1.03, @cx, @cy)
    if @label
      @label[0].stop()
      @label[0].attr({ r: 7.5 })
      @label[1].attr({ "font-weight": 800 })
  , ->
    @sector.animate({ transform: 's1 1 ' + @cx + ' ' + @cy}, 50, "bounce")
    if @label
      @label[0].animate({ r: 5 }, 50, "bounce")
      @label[1].attr({ "font-weight": 400 })
  )

removeMeasurementResults = ->
  @r.clear() if @r?

newOperatorInstanceClick = =>
  mousePos = @stage.getMousePosition()
  operator = getOperator()

  [lineIds, y] = findLinesY(mousePos['y'], operator.size)
  op = newOperatorInstance(lineIds, mousePos['x'], y, operator)

  if operator.type == "controlled"
    newMousePos = @stage.getMousePosition()
    measurement = @operators.findAllByType('measurement').findClosest(newMousePos['x'], newMousePos['y'])
    op.measurement = measurement
    op.renderMeasurementConnection(@operatorsLayer, true)
    
    # jquery .one not working in this situation
    $(@stage.getContent()).on('mousemove.controlled', =>
      newMousePos = @stage.getMousePosition()
      measurement = @operators.findAllByType('measurement').findClosest(newMousePos['x'], newMousePos['y'])
      op.measurement = measurement
      op.moveMeasurementConnection(@operatorsLayer, true)
    )
    $(@stage.getContent()).off('click.normal')
    $(@stage.getContent()).on('click.controlled', =>
      $(@stage.getContent()).off('click.controlled')
      $(@stage.getContent()).off('mousemove.controlled')
      bindStageClick()

      newMousePos = @stage.getMousePosition()
      measurement = @operators.findAllByType('measurement').findClosest(newMousePos['x'], newMousePos['y'])
      op.measurement = measurement
      op.moveMeasurementConnection(@operatorsLayer, true)
    )

setMode = (mode) ->
  if mode != "run" and @operators?
    ensureNoVerticalLine()
    unhighlightAllMeasurements()
    removeMeasurementResults()
    removeResults()
    hideResultsContainer()
    @oldOpmId = undefined
  $("#controlLinks > li > a").removeClass("active")
  $("#controlLinks > li > #" + mode).addClass("active")
  @mode = mode

getMode = ->
  return @mode

stageClick = ->
  switch getMode()
    when "add" then newOperatorInstanceClick()
    when "move" then moveOperatorClick()
    when "delete" then deleteOperatorClick()
    when "run" then inspectClick()

newOperatorInstance = (lines, x, y, operator) ->
  op = @operators.new(lines, x, y, operator.type, operator.id, operator.symbol, operator.size)
  op.render(@operatorsLayer, true)
  return op

setupDropdowns = ->
  $('#operatorType').on('change', ->
    changeDropdown($(@).val())
  )
  changeDropdown('gate')

changeDropdown = (opType) ->
  operators = window.GATES
  operators = window.MEASUREMENTS if opType == 'measurement'
  operators = window.CONTROLLED_GATES if opType == 'controlled'

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
  $('#run').on('click', -> run(); setMode('run'); return false)
  $('#save').on('click', -> save(); return false)
  $('#addLine').on('click', -> addLine(); return false)
  $('#deleteLine').on('click', -> deleteLine(); return false)
  $('#newOperator').on('click', -> newOperator(); return false)

newOperator = ->
  $('#newOperatorForm').dialog("open")

setupNewOperatorForm = ->
  $('#newOperatorForm').dialog({
    autoOpen: false
    height: 300
    width: 350
    modal: true
    buttons:
      "Submit": =>
        data = {
          name: $("#name").val()
          symbol: $("#symbol").val()
          type: $("#type").val()
          size: parseInt($("#size").val())
          matrix: @matrixInput.value()
        }
        $.post('/operators', {operator: JSON.stringify(data)}).done((rData) =>
          listData = {
            id: rData['id']
            name: data['name']
            size: data['size']
            symbol: data['symbol']
            type: data['type']
          }
          list =  switch data['type']
            when "gate" then window.GATES
            when "measurement" then window.MEASUREMENTS
            when "controlled" then window.CONTROLLED_GATES
          list.push(listData)

          # If type already selected, add to dropdown
          $('#operatorId').append($("<option></option>").attr("value", listData['id']).text(listData['name'])) if data['type'] == operatorType()
        )

        $('#newOperatorForm').dialog("close")
      "Cancel": ->
        $(@).dialog("close")
    close: =>
      # Clear form
      $('#name').val('')
      $('#symbol').val('')
      $('#type').prop('selectedIndex', 0)
      $('#size').val('')
      @matrixInput.render()
  })
  @matrixInput = new MatrixInput({
    el: $('#matrix')
    sizeEl: $('#size')
    class: "ui-widget-content ui-corner-all matrixInputBox"
  })
  @matrixInput.render()

# Initialises the page with a new stage
init = ->
  setupNewOperatorForm()
  setupResultsContainer()
  setupDropdowns()
  setMode('add')
  @stage = newStage('canvasContainer')
  bindStageClick()
  bindLinkClick()

  @linesLayer = newLayer(@stage)
  @lines = new Collection(Line)

  @operatorsLayer = newLayer(@stage)
  @operators = new Collection(Operator)

  # Define last so on top of other layers
  @inspectorsLayer = newLayer(@stage)

  if existingCircuit()
    loadCircuit()
  else
    setupNewCircuit()

# Load operators then run passed function
bootstrap = (func) ->
  $.get("/operators.json").done((data) ->
    gates = []
    measurements = []
    controlled_gates = []

    _.each(data, (op) =>
      op = op['operator']
      list =  switch op['type']
        when "gate" then gates
        when "measurement" then measurements
        when "controlled" then controlled_gates
      list.push(op)
    )

    window.GATES = gates
    window.MEASUREMENTS = measurements
    window.CONTROLLED_GATES = controlled_gates
    func()
  )

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
  $('#initialState').val(circuit['initial_state'])

  @lines.add(circuit['lines'])
  @lines.render(linesLayer)

  # We need to add controlled gates seperately
  otherOps = _.reject(circuit['operators'], (h) -> h['operator_type'] == 'controlled')
  controlledOps = _.filter(circuit['operators'], (h) -> h['operator_type'] == 'controlled')

  @operators.addFromArrays(_.map(otherOps, (h) ->
    op = getOperatorByIdType(h['operator_id'], h['operator_type'])
    return [h['id'], h['lines'], h['x'], h['y'], h['operator_type'], h['operator_id'], op.symbol, op.size]
  ))
  @operators.addFromArrays(_.map(controlledOps, (h) ->
    op = getOperatorByIdType(h['operator_id'], h['operator_type'])
    measurement = @operators.findAllByType('measurement').findById(h['measurement_id'])
    return [h['id'], h['lines'], h['x'], h['y'], h['operator_type'], h['operator_id'], op.symbol, op.size, measurement]
  ))
  @operators.render(@operatorsLayer)

  # Show previous iterations of circuit
  showIterations(circuit)

showIterations = (circuit) ->
  html = "<ul>"

  _.each(circuit['iterations'], (iteration) ->
    url = iteration['v_id']

    html += "<li" + (if iteration['current'] then " class='current'" else "") + ">"
    html += "<a href='" + iteration["url"] + "'>" unless iteration['current']
    html += iteration['v_id'] + " - " + iteration['modified']
    html += "</a>" unless iteration['current']
    html += "</li>"
  )

  html += "</ul>"
  $('#iterations').html(html)

genHash = ->
  operators = @operators.toArray()
  hash = {
    operators: operators
    lines: @lines.count()
    initial_state: $('#initialState').val()
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

showResultsContainer = ->
  $("#resultsContainer").dialog("open")

hideResultsContainer = ->
  $("#resultsContainer").dialog("close")
  $("#inspectMessage").show()

setupResultsContainer = ->
  $("#resultsContainer").dialog({
    autoOpen: false
    width: 500
    height: 400
    position: ['left', 'bottom']
  })

run = ->
  # TODO Is this RESTul?
  $.post('/circuits/run', {circuit: JSON.stringify(genHash())}).done((data) =>
    @resultsData = data['results']
    @measurementResultsData = data['probabilities']

    showResultsContainer()

    # _.each(data['probabilities'], (results, num) ->
    #   console.log("Measurement " + num)
    #   _.each(results, (prob, result) ->
    #     console.log("Results " + result + " wp " + prob)
    #   )
    # )
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
  bootstrap(init)
