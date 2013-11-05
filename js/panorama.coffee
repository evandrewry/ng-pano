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
  "lib/three"
  "lib/detector"
  "cs!trackball"
  "data/data"
  "lib/angular"
  "cs!$safeApply"
],

(THREE, Detector, Trackball, data, ng) ->

  pano = ng.module 'panorama', ['angular.safeApply']

  pano.value 'DEFAULT_FOV', 70
  pano.value 'DEFAULT_FRAME_RATE', 15
  pano.value 'DEFAULT_SPHERE_RADIUS', 500
  pano.value 'DEFAULT_FOV', 70


  pano.factory 'TEXTURE', ->
    data.textures

  pano.factory 'Clock', ['DEFAULT_FRAME_RATE', (DEFAULT_FRAME_RATE) ->
    callbacks = []
    lastFrame = new Date().getTime()
    frameRate = DEFAULT_FRAME_RATE
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
  ]

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

  pano.factory 'Camera', ['Trackball', 'DEFAULT_FOV', 'DEFAULT_SPHERE_RADIUS', (Trackball, DEFAULT_FOV, DEFAULT_SPHERE_RADIUS) ->
    camera = new THREE.PerspectiveCamera DEFAULT_FOV, window.innerWidth / window.innerHeight, 1, 1100
    camera.target = new THREE.Vector3 0, 0, 0
    camera.trackball = ->
      Trackball.clamp()

      phi = Trackball.phi()
      theta = Trackball.theta()

      camera.target.x = DEFAULT_SPHERE_RADIUS * Math.sin(phi) * Math.cos(theta)
      camera.target.y = DEFAULT_SPHERE_RADIUS * Math.cos(phi)
      camera.target.z = DEFAULT_SPHERE_RADIUS * Math.sin(phi) * Math.sin(theta)

      pos = camera.target.clone().normalize().multiplyScalar(-20)
      camera.position.set pos.x, pos.y, pos.z

      camera.lookAt camera.target
    return camera
  ]

  pano.factory 'SphereFactory', ['DEFAULT_SPHERE_RADIUS', (DEFAULT_SPHERE_RADIUS) ->
    (textureUrl, cb) -> 
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
      group sphere THREE.ImageUtils.loadTexture textureUrl, undefined, cb
  ]

  pano.factory 'Trackball', -> new Trackball()

  pano.factory 'Panorama',
  [
    '$rootScope',
    'Trackball',
    'Clock',
    'Renderer',
    'Camera',
    'SphereFactory',
    'Projector',
    'Scene',
    'DEFAULT_FOV',
    'TEXTURE',
    '$safeApply',

    ($rootScope, Trackball, Clock, Renderer, Camera, SphereFactory, Projector, Scene, DEFAULT_FOV, TEXTURE, $safeApply) ->
      class Panorama
        onrender: []
        constructor: ->
          @setTexture TEXTURE[@currentTexture = 0]
          Renderer.setSize window.innerWidth, window.innerHeight
          Renderer.sortObjects = false
          @animate()

          window.addEventListener 'resize', (=>@onresize()), false

        onresize: =>
          Camera.aspect = window.innerWidth / window.innerHeight
          Camera.updateProjectionMatrix()
          Renderer.setSize(window.innerWidth / window.innerHeight)
        render: (force) =>
          Camera.trackball()
          Renderer.render Scene, Camera if Trackball.stale or force
          cb() for cb in @onrender
          Clock.tick()
        animate: =>
          requestAnimationFrame @animate
          @render()
        nextTexture: =>
          @currentTexture += 1
          @setTexture TEXTURE[@currentTexture]
        setTexture: (textureUrl) =>
          $rootScope.$broadcast 'pano.loading'
          @loading = true
          @remove() if @group
          @group = SphereFactory textureUrl, =>
            @render true
            $rootScope.$broadcast 'pano.load'
            @loading = false
          Scene.add @group
        attach: (scope, position) ->
          @registerCallback ->
            scope.onscreen = Projector.getScreenPosition(position)
            if scope.onscreen
              proj = Projector.getScreenPosition(position.clone(), Camera)
              if proj
                $safeApply scope, ->
                  scope.x = proj.x
                  scope.y = proj.y
        remove: =>
          Scene.remove @group

        registerCallback: (cb) =>
          @onrender.push cb
      new Panorama()
  ]


  pano.directive 'panorama',
  [
    'Panorama'
    'Renderer'
    'MARKERS'

    (Panorama, Renderer, MARKERS) ->
      template: '<div ng-transclude></div>'
      replace: true
      transclude: true
      controllerAs: 'PanoramaCtrl'
      controller: ['Panorama', (Panorama) ->
        Panorama
      ]
      link: (scope, elem, attrs) ->
        elem.append Renderer.domElement
  ]
