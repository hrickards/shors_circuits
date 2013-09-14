class Operator
  constructor: (@id, @lines, @x, @y, @operatorType, @operatorId, @symbol, @size) ->
  render: (layer, draw) ->
    width = 50
    height = 50 * @size

    group = new Kinetic.Group()
    rect = new Kinetic.Rect
      x: @x
      y: @y
      width: width
      height: height
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

    group.add(rect)
    group.add(text)
    layer.add(group)
    layer.draw() if draw
  toHash: ->
    # Use x as the ID because we want to be sorted in running order
    return {id: @x, operatorType: @operatorType, operatorId: @operatorId, lines: @lines}

window.Operator = Operator
