class Operator
  constructor: (@id, @lines, @x, @y, @operatorType, @operatorId, @symbol, @size, @measurement) ->
    @width = 50
    @height = 50 * size
  changePosition: (x, y) ->
    # setPosition not working, presumably due to 0 width and height on group
    @group.move(x-@x, y-@y)
    @x = x
    @y = y
    @moveMeasurementConnection() if @measurement?
  unrender: (layer, draw) ->
    @group.remove()
    @unrenderMeasurementConnection() if @measurement?
    layer.draw() if draw
  render: (layer, draw) ->
    @group = new Kinetic.Group()
    rect = new Kinetic.Rect
      x: @x
      y: @y
      width: @width
      height: @height
      fill: 'white'
      stroke: 'black'
      strokeWidth: 3
    rect.setOffset
      x: rect.getWidth() / 2
      y: rect.getHeight() / 2
    text = new Kinetic.Text
      x: @x
      y: @y
      text: @symbol
      fontSize: 20
      fontFamily: 'Arial'
      fill: 'black'
    text.setOffset
      x: text.getWidth() / 2
      y: text.getHeight() / 2

    @renderMeasurementConnection(layer) if @measurement?

    @group.add(rect)
    @group.add(text)
    layer.add(@group)
    layer.draw() if draw
  moveMeasurementConnection: ->
    @line.setPoints(@calcMeasurementConnectionPoints())
  unrenderMeasurementConnection: ->
    @line.remove()
  renderMeasurementConnection: (layer, draw) ->
    @line = new Kinetic.Line
      points: @calcMeasurementConnectionPoints()
      stroke: 'black'
      strokeWidth: 1.0
      lineCap: 'round'
      lineJon: 'round'
    layer.add(@line)
    layer.draw() if draw
  calcMeasurementConnectionPoints: ->
    minX = @x - @width / 2
    maxX = @x + @width / 2
    minY = @y - @height / 2
    maxY = @y + @height / 2

    minMeasurementX = @measurement.x - @measurement.width / 2
    maxMeasurementX = @measurement.x + @measurement.width / 2
    minMeasurementY = @measurement.y - @measurement.height / 2
    maxMeasurementY = @measurement.y + @measurement.height / 2

    [startX, endX] = findStartEnd(minX, maxX, minMeasurementX, maxMeasurementX)
    [startY, endY] = findStartEnd(minY, maxY, minMeasurementY, maxMeasurementY)

    startPos = {x: startX, y: startY}
    middlePos = {x: startX, y: endY}
    endPos = {x: endX, y: endY}
    return [startPos, middlePos, endPos]


  # Operators should have ascending IDs from left to right, but also need to allow for operators
  # with the same x.
  # TODO Do this a better way
  # runId: ->
  # return parseInt(padNumber(@x, 4) + padNumber(@id, 3))
  
  toHash: ->
    hash = {id: @id, lines: @lines, x: @x, y: @y, operatorType: @operatorType, operatorId: @operatorId}
    hash['measurementId'] = @measurement.id if @measurement?
    return hash

  # toHash: ->
  #   hash = {id: @runId(), operatorType: @operatorType, operatorId: @operatorId, lines: @lines}
  #   hash['controlInput'] = @measurement.runId() if @measurement?
  #   return hash

window.Operator = Operator

findStartEnd = (min, max, minMeasurement, maxMeasurement) ->
  if (max <= minMeasurement)
    start = max
    end = minMeasurement
  else if (min >= maxMeasurement)
    start = min
    end = maxMeasurement
  else
    rightmostLeft = if min <= minMeasurement then minMeasurement else min
    leftmostRight = if max >= maxMeasurement then maxMeasurement else max
    start = (leftmostRight + rightmostLeft) / 2
    end = start
  return [start, end]

# http://jsperf.com/ways-to-0-pad-a-number/15
padNumber = (number, pad) ->
  n = Math.pow(10, pad)
  return if number < n then ("" + (n + number)).slice(1) else "" + number
