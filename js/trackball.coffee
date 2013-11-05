define ->
  class Trackball
    stale: false
    fov: 70
    mouse:
      active: false
      x: 0
      y: 0
      lat: 0
      lon: 0
      down:
        x: undefined
        y: undefined
        lat: undefined
        lon: undefined
    constructor: ->
      document.addEventListener "mousedown", @mousedown, false
      document.addEventListener "mousemove", @mousemove, false
      document.addEventListener "mouseup", @mouseup, false
      document.addEventListener "mousewheel", @mousewheel, false
      document.addEventListener "DOMMouseScroll", @mousewheel, false
    phi: -> (90 - @mouse.lat) * Math.PI / 180
    theta: -> @mouse.lon * Math.PI / 180
    clamp: =>
      @mouse.lat = Math.max(-85, Math.min(85, @mouse.lat))
    mousedown: (event) =>
      event.preventDefault()
      @mouse.active = true
      @mouse.down.x = event.clientX
      @mouse.down.y = event.clientY
      @mouse.down.lon = @mouse.lon
      @mouse.down.lat = @mouse.lat
    mouseup: (event) =>
      @mouse.active = false
    mousemove: (event) =>
      if @mouse.active
        @mouse.lon = (@mouse.down.x - event.clientX) * 0.1 + @mouse.down.lon
        @mouse.lat = (event.clientY - @mouse.down.y) * 0.1 + @mouse.down.lat
        @stale = true
      @mouse.x = (event.clientX / window.innerWidth) * 2 - 1
      @mouse.y = -(event.clientY / window.innerHeight) * 2 + 1
    mousewheel: (event) =>
