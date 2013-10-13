class VerticalLine
  constructor: (@x) ->

  startPos: -> return {x: @x, y: 0}
  endPos: -> return {x: @x, y: 1000}
  linePoints: -> return [@startPos(), @endPos()]

  # Shows the line
  render: (layer, draw) ->
    @line = new Kinetic.Line
      points: @linePoints()
      stroke: '#555'
      strokeWidth: 1.5
      lineCap: 'round'
      lineJoin: 'round'
    layer.add(@line)
    layer.draw() if draw
  changePosition: (x) ->
    @x = x
    @line.setPoints(@linePoints())
  unrender: (layer, draw) ->
    @line.remove()
    layer.draw() if draw

window.VerticalLine = VerticalLine
