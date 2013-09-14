class Collection
  constructor: (@model) ->
    @models = []
  highestId: =>
    hId = _.max(@models, (model) -> return model.id).id
    if hId?
      return hId
    else
      return -1
  add: (num) =>
    num = 1 if Num?
    _(num).times =>
      @new()
  new: (args...) =>
      newId = @highestId() + 1
      model = new @model(newId, args[0], args[1], args[2], args[3], args[4], args[5], args[6])

      # TODO Do this a *much* better way. 
      @models.push(model)
      return model
  render: (layer) =>
    _.each(@models, (model) ->
      model.render(layer)
    )
    layer.draw()
  findClosestByY: (y, size) =>
    size = 1 if Size?
    return _.sortBy(@models, (model) -> Math.abs(model.y - y)).slice(0, size)

  toHash: ->
    return _.map(@models, (model) -> return model.toHash())
  count: ->
    return @models.length


window.Collection = Collection
