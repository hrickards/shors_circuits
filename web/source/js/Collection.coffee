class Collection
  constructor: (@model, models) ->
    @models = models || []
  highestId: =>
    hId = _.max(@models, (model) -> return model.id).id
    if hId?
      return hId
    else
      return -1
  add: (num) =>
    num = 1 unless num?
    _(num).times =>
      @new()
  new: (args...) =>
      newId = @highestId() + 1
      model = new @model(newId, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9])

      # TODO Do this a *much* better way. 
      @models.push(model)
      return model
  render: (layer) =>
    _.each(@models, (model) ->
      model.render(layer)
    )
    layer.draw()
  remove: (op) ->
    index = _.indexOf(@models, op)
    @models.splice(index, 1)

  findClosestByY: (y, size) =>
    size = 1 unless size?
    return _.sortBy(@models, (model) -> Math.abs(model.y - y)).slice(0, size)
  findAllByType: (type) =>
    return new Collection(@model, _.filter(@models, (model) -> model.operatorType == type))
  findClosest: (x, y) =>
    window.models = @models
    return _.sortBy(@models, (model) -> Math.pow((model.x - x), 2) + Math.pow((model.y - y), 2))[0]

  toHash: ->
    return _.map(@models, (model) -> return model.toHash())
  count: ->
    return @models.length


window.Collection = Collection
