# jquery globally
//= require vendor/jquery-ui
//= require vendor/kinetic
//= require vendor/underscore
//= require vendor/raphael
//= require vendor/g.raphael
//= require vendor/g.pie
//= require vendor/bootstrap-editable
//= require vendor/bootstrap-switch
//= require vendor/bootstrap-select
//= require Collection
//= require Line
//= require Operator
//= require VerticalLine
//= require MatrixInput

getMousePosition = ->
  mousePos = @stage.getMousePosition()
  mousePos['x'] -= @offset['x']
  mousePos['y'] -= @offset['y']
  return mousePos

# Returns new canvas stage for passed canvas ID
newStage = (canvasId) ->
  canvasWidth = $('#' + canvasId).width()
  canvasHeight = $('#' + canvasId).height()
  stage = new Kinetic.Stage
    container: canvasId
    width: canvasWidth
    height: canvasHeight
    dragBoundFunc: (pos) =>
      @offset = pos
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
  mousePos = getMousePosition()
  op = @operators.findClosest(mousePos['x'], mousePos['y'])

  if op.operatorType == 'measurement'
    connectedControlled = @operators.findAllByType('controlled').filter((controlled) -> controlled.measurement == op)
    _.map(connectedControlled, (controlled) -> @operators.remove controlled)

  @operators.remove op, @operatorsLayer, true

moveOperatorClick = ->
  mousePos = getMousePosition()
  op = @operators.findClosest(mousePos['x'], mousePos['y'])
  $(@stage.getContent()).off('click.normal')
  $(@stage.getContent()).on('mousemove', =>
    mousePos = getMousePosition()
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

highlightOperator = (opm) ->
  opm.highlight()
  @operatorsLayer.draw()

unhighlightAllOperators = ->
  if @operators?
    _.each(@operators.models, (op) ->
      op.unhighlight()
    )
    @operatorsLayer.draw()

operatorDetailPath = (id) ->
  return "/operators/details/" + id

inspectOperatorClick = ->
  unhighlightAllOperators()
  mousePos = getMousePosition()
  operator = @operators.findClosest(mousePos['x'], mousePos['y'])
  if operator?
    highlightOperator(operator)
    $('#inspectOperatorMessage').hide()
    $.getJSON(operatorDetailPath(operator.operatorId)).done((data) ->
      op = data['operator']
      type = op['type']
      height = op['size'] * 80

      html = "<div><b>Name:</b> " + op['name'] + "</div>"
      html += "<div><b>Size:</b> " + op['size'] + "</div>"
      html += "<div><b>Symbol:</b> " + op['symbol'] + "</div>"
      html += "<div><b>Type:</b> " + type.charAt(0).toUpperCase() + type.slice(1) + "</div>"
      if type == "controlled"
        html += "<div><b>Matrix:</b>"
        _.each(op['matrix'], (datum) ->
          value = datum[0]
          matrix = datum[1]
          html += "<div>" + value + " : <img src='/latex/math/" + matrix + ".png?height=" + height + "'/></div>"
        )
        html += "</div>"
      else
        html += "<div><b>Matrix:</b> <img src='/latex/math/" + op['matrix'] + ".png?height=" + height + "'/>"
      $("#operatorDetails").html(html)
    )


inspectRunClick = ->
  $("#inspectMessage").hide()
  mousePos = getMousePosition()
  ensureVerticalLineAt(mousePos['x'])

  op = @operators.leftOf(mousePos['x']).findClosestByX(mousePos['x'])
  oId = -1
  oId = op.id if op?
  showResults(oId)

  # Find closest measurement
  unhighlightAllOperators()
  opm = @operators.findAllByType('measurement').findClosestByX(mousePos['x'])
  if opm?
    highlightOperator(opm)
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
  keys = _.filter(_.keys(results), (key) -> key != "expected" and key != "variance")
  labels = _.map(keys, (key) -> key + " wp " + results[key][0])
  values = _.map(keys, (key) -> results[key][1])

  html = "<div>Expected value: <img src='/latex/math/" + results['expected'] + ".png?height=30'/></div>"
  html += "<div>Variance: <img src='/latex/math/" + results['variance'] + ".png?height=30'/></div>"

  $('#measurementsDataContainer').html(html)

  unless @r?
    cont = $('#measurementsChartContainer')
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
  mousePos = getMousePosition()
  operator = getOperator()

  [lineIds, y] = findLinesY(mousePos['y'], operator.size)
  op = newOperatorInstance(lineIds, mousePos['x'], y, operator)

  if operator.type == "controlled"
    newMousePos = getMousePosition()
    measurement = @operators.findAllByType('measurement').findClosest(newMousePos['x'], newMousePos['y'])
    op.measurement = measurement
    op.renderMeasurementConnection(@operatorsLayer, true)
    
    # jquery .one not working in this situation
    $(@stage.getContent()).on('mousemove.controlled', =>
      newMousePos = getMousePosition()
      measurement = @operators.findAllByType('measurement').findClosest(newMousePos['x'], newMousePos['y'])
      op.measurement = measurement
      op.moveMeasurementConnection(@operatorsLayer, true)
    )
    $(@stage.getContent()).off('click.normal')
    $(@stage.getContent()).on('click.controlled', =>
      $(@stage.getContent()).off('click.controlled')
      $(@stage.getContent()).off('mousemove.controlled')
      bindStageClick()

      newMousePos = getMousePosition()
      measurement = @operators.findAllByType('measurement').findClosest(newMousePos['x'], newMousePos['y'])
      op.measurement = measurement
      op.moveMeasurementConnection(@operatorsLayer, true)
    )

setMode = (mode) ->
  if mode != "run" and @operators?
    ensureNoVerticalLine()
    unhighlightAllOperators()
    removeMeasurementResults()
    removeResults()
    hideResultsContainer()
    @oldOpmId = undefined
  if mode != "inspect"
    hideInspectorContainer()
    unhighlightAllOperators()
  if @stage?
    if mode == "pan"
      @stage.setDraggable(true)
    else
      @stage.setDraggable(false)
  $("#controlLinks button").removeClass("btn-primary")
  $("#controlLinks button").addClass("btn-default")
  $("#controlLinks #" + mode).removeClass("btn-default")
  $("#controlLinks #" + mode).addClass("btn-primary")
  @mode = mode

getMode = ->
  return @mode

stageClick = ->
  switch getMode()
    when "add" then newOperatorInstanceClick()
    when "move" then moveOperatorClick()
    when "delete" then deleteOperatorClick()
    when "run" then inspectRunClick()
    when "inspect" then inspectOperatorClick()

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
    description = operator.name
    if operator.size > 1
      description +=  " (" + operator.size + " qubits)"
    $('#operatorId').append($("<option></option>").attr("value", operator.id).text(description))
  )
  $('#operatorId').selectpicker('refresh')

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

flashMessage = (text, type) ->
  alert = $('<div class="alert-top alert alert-' + type + ' login' + type + '"><a class="close">&#215;</a>' + text + '</div>').hide()
  if ($('#flash > .login' + type).length)
    $('#flash > .login' + type).slideUp('slow', ->
      $('#flash > .login' + type).remove()
      alert.appendTo('#flash').slideDown('slow')
    )
  else
    alert.appendTo('#flash').slideDown('slow')

bindLinkClick = ->
  $('#add').on('click', -> setMode('add'); return false)
  $('#move').on('click', -> setMode('move'); return false)
  $('#delete').on('click', -> setMode('delete'); return false)
  $('#run').on('click', -> run(); setMode('run'); return false)
  $('#inspect').on('click', -> showInspectorContainer(); setMode('inspect'); return false)
  $('#save').on('click', -> save(); return false)
  $('#usave').on('click', -> flashMessage("You must login to save a circuit!", 'warning'); return false)
  $('#addLine').on('click', -> addLine(); return false)
  $('#deleteLine').on('click', -> deleteLine(); return false)
  $('#newOperator').on('click', -> newOperator(); return false)
  $('#pan').on('click', -> setMode('pan'); return false)
  $('#center').on('click', -> centerStage(); return false)

centerStage = ->
  @stage.setPosition(0, 0)
  @stage.draw()
  @offset = {x: 0, y: 0}

newOperator = ->
  $('#newOperatorModal').show()

closeNewOperatorForm = ->
  $('#newOperatorModal').hide()
  $('#name').val('')
  $('#symbol').val('')
  $('#type').prop('selectedIndex', 0)
  $('#size').val('')
  $('#controlledFormContent').html('')
  @controlledMatrixInputs = {}
  switchFormNormal()
  @matrixInput.render()

switchFormNormal = ->
  $("#normalForm").show()
  $("#controlledForm").hide()

switchFormControlled = ->
  $("#normalForm").hide()
  $("#controlledForm").show()

removeFromControlled = ->
  ids = _($("#controlledFormContent").find("table")).map( (t) ->
    return parseInt(t.id.substr(6))
  )
  if ids.length > 0
    removeId = _(ids).max()
    delete @controlledMatrixInputs[removeId]
    $("#controlledFormContent > div.form-group").has("table#matrix" + removeId).remove()


addToControlled = ->
  ids = _($("#controlledFormContent").find("table")).map( (t) ->
    return parseInt(t.id.substr(6))
  )
  if ids.length > 0
    newId = _(ids).max() + 1
  else
    newId = 0

  html = '<div class="form-group form-group-norightmargin">'
  html += '<div class="col-lg-8">'
  html += '<label for="matrix' + newId + '">Matrix</label>'
  html += '<div>'
  html += '<table id="matrix' + newId + '">'
  html += '</table>'
  html += '</div>'
  html += '</div>'
  html += '<div class="col-lg-3">'
  html += '<label for="measured' + newId + '">Measured Value</label>'
  html += '<input type="text" name="measured' + newId + '" id="measured' + newId + '" class="form-control" />'
  html += '</div>'
  html += '</div>'
  $("#controlledFormContent").append(html)

  @controlledMatrixInputs[newId] = new MatrixInput({
    el: $('#matrix' + newId)
    sizeEl: $('#size')
    class: "form-control matrixInputBox"
  })
  @controlledMatrixInputs[newId].render()

setupNewOperatorForm = ->
  $('#newOperatorSubmit').on('click', =>
    if $("#type").val() == "controlled"
      matrix = _(@controlledMatrixInputs).map((m, id) -> [$("#measured" + id).val(), m.value()])
    else
      matrix = @matrixInput.value()
    data = {
      name: $("#name").val()
      symbol: $("#symbol").val()
      type: $("#type").val()
      size: parseInt($("#size").val())
      matrix: matrix
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
      $('#operatorId').selectpicker('refresh')
    )

    closeNewOperatorForm()
  )
  $("#type").on('change', ->
    if $(@).val() == "controlled"
      switchFormControlled()
    else
      switchFormNormal()
  )
  $('#newControlledMatrix').on('click', ->
    addToControlled()
  )
  $('#deleteControlledMatrix').on('click', ->
    removeFromControlled()
  )
  $('.closeOperator').click(->
    closeNewOperatorForm()
  )
  @controlledMatrixInputs = {}
  @matrixInput = new MatrixInput({
    el: $('#matrix')
    sizeEl: $('#size')
    class: "form-control matrixInputBox"
  })
  @matrixInput.render()
  closeNewOperatorForm()

switchHtmlCode = (id, text, checked, disabled) ->
  html  = '<div class="switchRow">' + text
  html += '<div id="' + id + 'Switch" class="make-switch switch-small" data-on="success" data-off="warning">'
  html += '<input type="checkbox"'
  html += ' checked' if checked
  html += ' disabled' if disabled
  html += '></div></div>'
  return html

setupFixedSwitches = (readable, editable) ->
  $("#switches").html(switchHtmlCode('readable', 'World readable: ', readable, true))
  $("#switches").append(switchHtmlCode('editable', 'World editable: ', editable, true))
  $("#readableSwitch").bootstrapSwitch()
  $("#editableSwitch").bootstrapSwitch()

setupEditableSwitches = (url, readable, editable) ->
  $("#switches").html(switchHtmlCode('readable', 'World readable: ', readable, false))
  $("#switches").append(switchHtmlCode('editable', 'World editable: ', editable, false))
  $("#readableSwitch").bootstrapSwitch()
  $("#editableSwitch").bootstrapSwitch()
  $("#readableSwitch").bootstrapSwitch('setAnimated', false)
  $("#editableSwitch").bootstrapSwitch('setAnimated', false)

  if (url.length > 0)
    $("#readableSwitch").on("switch-change", (e, data) ->
      updateSwitch('readable', data.value, url)
    )
    $("#editableSwitch").on("switch-change", (e, data) ->
      updateSwitch('editable', data.value, url)
    )

updateSwitch = (key, value, url) ->
  data = {}
  data[key] = value
  $.post(url, data)

setupFixedName = (name) ->
  $('#circuitName').text(name)

setupEditableName = (url, name) ->
  setupFixedName(name)
  $('#circuitName').editable(
    type: 'text'
    # xeditable needs this, but cid and vid are actually in the URL
    pk: 1
    url: url
    title: 'Change circuit name'
    placement: 'bottom'
  )


# Initialises the page with a new stage
init = ->
  @offset = {'x': 0, 'y': 0}
  setupNewOperatorForm()
  setupResultsContainer()
  setupInspectorContainer()
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
  else if existingSessionCircuit()
    loadSessionCircuit()
  else
    setupNewCircuit()

  # If user not logged in, save circuit in local storage
  if $('#usave').length > 0
    bindSaveLocally()

# Save circuit in local storage
bindSaveLocally = ->
  $(window).bind('beforeunload', ->
    circuit = genHash()
    circuit['name'] = circuit['name'] + " (copy)" if existingCircuit()
    sessionStorage.setItem('circuit', JSON.stringify({circuit:circuit}))
  )

# Load operators then run passed function
bootstrap = (func) ->
  $.getJSON(operatorsPath()).done((data) ->
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
  setupEditableName('', 'Untitled Circuit')
  setupEditableSwitches('', true, false)
  $('#iterations').hide()
  @lines.add(3)
  @lines.render(@linesLayer)

existingCircuit = ->
  parts = window.location.pathname.split(".")[0].split("/")
  return parts[parts.length - 3] == "circuits"

existingSessionCircuit = ->
  return sessionStorage.getItem('circuit')?

operatorsPath = ->
  splits = window.location.pathname.split("/")
  path = "/operators"
  path += "/" + splits[2] if splits.length > 2
  return path + ".json"

dataPath = (infix) ->
  infix = "" unless infix?
  basePath = window.location.pathname.split(".")[0]
  return basePath + infix + ".json"

loadCircuit = ->
  $.getJSON(dataPath()).done((data) =>
    renderCircuit(data['circuit'])
  ).error( ->
    flashMessage("You don't have permission to access that circuit! If this is your circuit, make sure you're logged in.", 'danger')
  )

loadSessionCircuit = ->
  circuit = JSON.parse(sessionStorage.getItem('circuit'))['circuit']
  sessionStorage.removeItem('circuit')
  circuit['can_change_settings'] = true
  circuit['unsaved'] = true
  renderCircuit(circuit)

renderCircuit = (circuit) =>
  $('#save').attr('title', 'Update')
  $('#initialState').val(circuit['initial_state'])

  if(circuit['unsaved'])
    setupEditableName('', circuit['name'])
    setupEditableSwitches('', circuit['world_readable'], circuit['world_editable'])
    $('#iterations').hide()
  else if(circuit['can_change_settings'])
    setupEditableName(dataPath('/name'), circuit['name'])
    setupEditableSwitches(dataPath('/switches'), circuit['world_readable'], circuit['world_editable'])
  else
    setupFixedName(circuit['name'])
    setupFixedSwitches(circuit['world_readable'], circuit['world_editable'])

  unless circuit['world_editable'] or circuit['can_change_settings']
    $("#save").attr("id", "usave")
    $('#usave').off('click')
    $('#usave').on('click', -> flashMessage("You don't have permission to do that!", 'danger'); return false)

  unless circuit['unsaved']
    subject = "Quantum Circuit: " + circuit['name']
    body = "Take a look at my quantum circuit at " + document.URL.split("#")[0] + "."
    html = "<a class='btn btn-default' href='mailto:?subject=" + encodeURIComponent(subject) + "&amp;body=" + encodeURIComponent(body) + "' title='Share Circuit'>Share Circuit</a>"
    $("#shareButton").html(html)
    
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
  showIterations(circuit) unless circuit['unsaved']

showIterations = (circuit) ->
  html = ""

  _.each(circuit['iterations'], (iteration) ->
    url = iteration['v_id']

    html += "<li" + (if iteration['current'] then " class='active'" else "") + "><a href='"
    if iteration['current']
      html += "#"
    else
      html += iteration["url"]
    html += "'>" + iteration['v_id'] + " - " + iteration['modified']
    html += "</a>" unless iteration['current']
    html += "</li>"
  )
  $('#navIterations').html(html)

genHash = ->
  operators = @operators.toArray()
  hash = {
    operators: operators
    lines: @lines.count()
    initial_state: $('#initialState').val()
    name: $('#circuitName').text()
    world_readable: $('#readableSwitch').bootstrapSwitch('status')
    world_editable: $('#editableSwitch').bootstrapSwitch('status')
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

showInspectorContainer = ->
  $('#inspectorContainer').show()
  $("#inspectorContainer").draggable(
    handle: '.panel-heading'
  )

hideInspectorContainer = ->
  $('#inspectorContainer').hide()
  $('#inspectOperatorMessage').show()
  $("#operatorDetails").html("")

setupInspectorContainer = ->
  $('.closeInspector').click(->
    hideInspectorContainer()
  )
  hideInspectorContainer()

showResultsContainer = ->
  $("#resultsContainer").show()
  $("#resultsContainer").draggable(
    handle: '.panel-heading'
  )

hideResultsContainer = ->
  $("#resultsContainer").hide()
  $("#inspectMessage").show()

setupResultsContainer = ->
  $('.closeResults').click(->
    hideResultsContainer()
  )
  hideResultsContainer()

run = ->
  # TODO Is this RESTul?
  $.post('/circuits/run', {circuit: JSON.stringify(genHash())}).done((data) =>
    if 'error' of data
      error = data['error']
      height = error['size'] * 40
      flashMessage("Unfortunately we couldn't run that circuit. Your matrix <img src='/latex/math/" + error['matrix'] + ".png?height=" + height + "'/> should have been " + error['mtype'] + " but wasn't. Please fix the problem and try again.", 'danger')
    else
      @resultsData = data['results']
      @measurementResultsData = data['probabilities']

      showResultsContainer()
  ).error(->
    flashMessage("Something went wrong when running that circuit.", 'danger')
  )

resize = ->
  $("#sidebar").height($("#page").height() - $("#header").height())
  $("#canvasContainer").height($("#page").height() - $("#header").height())

  $(".matrixContainer").css('height', $(document).height() - 450)

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
  $('.selectpicker').selectpicker({
    width: '13em'
  })

  $(window).on('resizeEnd orientationchange', resize)

  resize()
  bootstrap(init)
