#  This file is part of the source code for ng-pano, an AngularJS
#  implementation of an equirectangular panorama viewer. Compatible with
#  any browser with support for WebGL or HTML5 Canvas.
#
#  Copyright © 2013 Evan Drewry
#  evandrewry@gmail.com
#  http://deth.ly
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

define [
  "lib/three",
  "lib/detector",
  "lib/tween",
  "data/data",
  "lib/angular",
  "cs!$safeApply"
], (THREE, Detector, TWEEN, data, ng) ->

  pano = ng.module 'panorama', ['angular.safeApply']

  pano.value 'DEFAULT_FOV', 70

  pano.factory 'TEXTURE', ->
    data.texture

  pano.factory 'Clock', ->
    callbacks = []
    lastFrame = new Date().getTime()
    frameRate = 15
    frameTime = 1000 / frameRate
    @add = (obj, handler) ->
      @callbacks.push binding: obj, handler: handler
    @remove = (handler) ->
      for cb, i in callbacks
        callbacks.splice i, 1 if cb.handler == handler
    @tick = ->
      now = new Date().getTime()
      if (now - lastFrame) > frameTime
        lastFrame = now
        cb.handler.call cb.binding for cb in callbacks
    this

  pano.factory 'Projector', ['Camera', (Camera) -> 
    projector = new THREE.Projector()
    projector.getScreenPosition = (target) ->
      proj = projector.projectVector(target.clone(), Camera)
      proj.x = (proj.x + 1) / 2 * window.innerWidth
      proj.y = -(proj.y - 1) / 2 * window.innerHeight
      angle = Math.acos(Camera.target.clone().normalize().dot(target.clone().normalize())) * 180 / Math.PI
      sameSide = (angle < 90)
      return x: proj.x, y: proj.y if (sameSide and proj.x > 0 and proj.x < window.innerWidth and proj.y > 0 and proj.y < window.innerHeight)
    return projector
  ]

  pano.factory 'Scene', ->
    new THREE.Scene()

  pano.factory 'Renderer', ->
    if Detector.webgl
      new THREE.WebGLRenderer()
    else
      new THREE.CanvasRenderer()

  pano.factory 'MARKERS', ->
    m = new THREE.Vector3(m.x, m.y, m.z) for m in data.markers

  pano.factory 'Camera', ['Trackball', 'DEFAULT_FOV', (Trackball, DEFAULT_FOV) ->
    camera = new THREE.PerspectiveCamera DEFAULT_FOV, window.innerWidth / window.innerHeight, 1, 1100
    camera.target = new THREE.Vector3 0, 0, 0
    camera.trackball = ->
      Trackball.clamp()

      phi = Trackball.phi()
      theta = Trackball.theta()

      camera.target.x = 500 * Math.sin(phi) * Math.cos(theta)
      camera.target.y = 500 * Math.cos(phi)
      camera.target.z = 500 * Math.sin(phi) * Math.sin(theta)

      pos = camera.target.clone().normalize().multiplyScalar(-20)
      camera.position.set pos.x, pos.y, pos.z

      camera.lookAt camera.target
    return camera
  ]

  pano.factory 'SphereFactory', ['TEXTURE', (TEXTURE) ->
    group = (sphere) ->
      group = new THREE.Object3D()
      group.add sphere
      group.position.x = 0
      group.position.y = 0
      group.position.z = 0
      return group
    sphere = (texture) ->
      geometry = if Detector.webgl
        new THREE.SphereGeometry(500, 600, 40)
      else
        #reduce number of poligons to improve performance
        new THREE.SphereGeometry(500, 600, 40)
      sphere = new THREE.Mesh geometry, new THREE.MeshBasicMaterial map: texture, wireframe: false
      sphere.overdraw = true unless Detector.webgl
      sphere.doubleSided = true
      sphere.scale.x = -1
      sphere
    (cb) -> group sphere THREE.ImageUtils.loadTexture TEXTURE, undefined, cb
  ]

  pano.factory 'Trackball', ->
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
        #@stale = false
        #vector = new THREE.Vector3(@mouse.x, @mouse.y, 0.5)
        #@projector.unprojectVector vector, @camera
        #ray = new THREE.Raycaster(@camera.position, vector.sub(@camera.position).normalize())
        #intersects = ray.intersectObjects(@scene.children)

      mousemove: (event) =>
        if @mouse.active
          @mouse.lon = (@mouse.down.x - event.clientX) * 0.1 + @mouse.down.lon
          @mouse.lat = (event.clientY - @mouse.down.y) * 0.1 + @mouse.down.lat
          @stale = true
        @mouse.x = (event.clientX / window.innerWidth) * 2 - 1
        @mouse.y = -(event.clientY / window.innerHeight) * 2 + 1

      mousewheel: (event) =>
        return
        #    if event.wheelDeltaY
        #      @fov -= event.wheelDeltaY * 0.05
        #    else if event.wheelDelta
        #      @fov -= event.wheelDelta * 0.05
        #    else @fov += event.detail * 1.0  if event.detail
        #    Camera.projectionMatrix.makePerspective @fov, window.innerWidth / window.innerHeight, 1, 1100
        #    @render()

    new Trackball()



  pano.factory 'Panorama',
  [
    'Trackball',
    'Clock',
    'Renderer',
    'Camera',
    'SphereFactory',
    'Projector',
    'Scene',
    'DEFAULT_FOV',
    'MARKERS',
    'TEXTURE',
    '$safeApply',

    (Trackball, Clock, Renderer, Camera, SphereFactory, Projector, Scene, DEFAULT_FOV, MARKERS, TEXTURE, $safeApply) ->
      class Panorama
        onrender: []
        constructor: ->
          @group = SphereFactory =>@render true
          Scene.add @group
          Renderer.setSize window.innerWidth, window.innerHeight
          Renderer.sortObjects = false
          @animate()

        render: (force) =>
          Camera.trackball()
          Renderer.render Scene, Camera if Trackball.stale or force
          cb() for cb in @onrender
          Clock.tick()
        animate: =>
          requestAnimationFrame @animate
          @render()
          TWEEN.update()

        registerCallback: (cb) =>
          @onrender.push cb
  ]


