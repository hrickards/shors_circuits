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
  addFromArrays: (as) ->
    _.each(as, (a) => @addFromArray(a))
  addFromArray: (a) ->
    model = new @model(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10])
    @models.push(model)
    return model
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
  remove: (model, layer, draw) ->
    index = _.indexOf(@models, model)
    @models[index].unrender(layer, draw)
    @models.splice(index, 1)
  removeLast: (layer, draw) ->
    model = @models.pop()
    model.unrender(layer, draw)
    return model
  removeWhere: (func, layer, draw) ->
    _.each(_.filter(@models, func), (model) =>
      @remove(model, layer, false)
    )
    layer.draw() if draw

  findClosestByY: (y, size) =>
    size = 1 unless size?
    return _.sortBy(@models, (model) -> Math.abs(model.y - y)).slice(0, size)
  findAllByType: (type) =>
    return new Collection(@model, _.filter(@models, (model) -> model.operatorType == type))
  findClosest: (x, y) =>
    return _.sortBy(@models, (model) -> Math.pow((model.x - x), 2) + Math.pow((model.y - y), 2))[0]
  findClosestByX: (x) =>
    return _.sortBy(@models, (model) -> Math.abs(model.x - x))[0]
  findById: (id) =>
    return _.find(@models, (model) -> model.id == id)
  leftOf: (x) =>
    return new Collection(@model, _.filter(@models, (model) -> model.x <= x))
  onLine: (line) =>
    return new Collection(@model, _.filter(@models, (model) -> _.contains(model.lines, line)))

  toHash: ->
    return _.map(@models, (model) -> return model.toHash())
  toArray: ->
    return _.map(@models, (model) -> return model.toHash())
  count: ->
    return @models.length


window.Collection = Collection
