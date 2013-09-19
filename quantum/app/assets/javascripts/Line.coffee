# Register line
class Line
  # @id = 0-indexed id of line
  constructor: (@id) ->
    @y = @id * 50 + 50
  y: 0
  startPos: -> return {x: 0, y: @y}
  endPos: -> return {x: 6000, y: @y}
 
  # Shows the line
  render: (layer, draw) ->
    @line = new Kinetic.Line
      points: [@startPos(), @endPos()]
      stroke: 'black'
      strokeWidth: 1.5
      lineCap: 'round'
      lineJoin: 'round'
    layer.add(@line)
    layer.draw() if draw
  unrender: (layer, draw) ->
    @line.remove()
    layer.draw() if draw

window.Line = Line
