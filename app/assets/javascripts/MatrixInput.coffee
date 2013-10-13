class MatrixInput
  constructor: (options) ->
    @el = options['el']
    @sizeEl = options['sizeEl']
    @class = options['class']
    @currentSize = 0
    @bind()

  bind: ->
    @sizeEl.on('change', =>
      @render()
    )

  size: ->
    return @sizeEl.val()

  render: ->
    return if @size() < 0
    delta = @size() - @currentSize
    if delta > 0
      @addRC(delta)
    else if delta < 0
      @removeRC(-delta)
    @currentSize = @size()

  addRC: (n) ->
    # Each row, add n cols
    _(@el.find('tr')).each( (row) => $(row).append(@nElements(n)))
    # Add n new rows of @size() length
    _(n).times( => @el.append(@row()))

  removeRC: (n) ->
    # Remove n new rows
    _(n).times( => @el.find('tr:last').remove() )
    # Each row, remove n cols
    _(@el.find('tr')).each( (row) =>
      _(n).times( => $(row).find('td:last').remove() )
    )
  
  element: ->
    return "<td><input class='" + @class + "'/></td>"

  nElements: (n) ->
    return _(n).range().map( => @element()).join('')

  row: ->
    return "<tr>" + @nElements(@size()) + "</tr>"

  value: ->
    value = []
    _(@el.find('tr')).each( (row) ->
      rowValue = []
      _($(row).find('td')).each( (col) ->
        rowValue.push($(col).val()))
      value.push(rowValue)
    )
    return value


window.MatrixInput = MatrixInput
