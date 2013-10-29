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
  "lib/angular",
  "cs!panorama",
  "cs!$safeApply",
], (ng) ->

  cwut = ng.module 'cwut', ['panorama']

  cwut.directive 'marker',
  [
    'Camera'
    'Projector'
    '$timeout'
    '$safeApply'

    (Camera, Projector,$timeout, $safeApply)->
      template: '<div ng-click="onclick()" ng-style="{left: x, top: y, \'margin-left\': offset}" ng-class="{\'active\': active}" ng-show="markerOnScreen && !ctrl.loading" ng-transclude></div>'
      scope:
        markerPosition: '='
        markerOnScreen: '='
      require: '^panorama'
      transclude: true
      replace: true
      link: (scope, elem, attrs, PanoramaCtrl) ->
        scope.ctrl = PanoramaCtrl
        PanoramaCtrl.registerCallback =>
          scope.markerOnScreen = Projector.getScreenPosition(scope.markerPosition)
          if scope.markerOnScreen
            proj = Projector.getScreenPosition(scope.markerPosition.clone(), Camera)
            if proj
              $safeApply scope, ->
                scope.x = proj.x
                scope.y = proj.y

        scope.active = false
        scope.onclick = -> scope.active = !scope.active
  ]

  cwut.directive 'markerPano', ->
      template: '<div panorama><div panorama-spinner></div><div marker data-marker-position="marker" data-marker-on-screen="marker.visible" ng-repeat="marker in markers"></div><div class="next-texture-btn" ng-click="next()"></div></div>'
      controller: ['$scope', 'Panorama', 'MARKERS', ($scope, Panorama, MARKERS) ->
          $scope.markers = MARKERS
          $scope.next = Panorama.nextTexture
      ]

  cwut.directive 'panoramaSpinner', ['$safeApply', ($safeApply) ->
    require: '^panorama'
    template: '<div ng-show="loading"><div class="spinner"></div></div>'
    replace: true
    compile: (tElem, tAttrs, transclude) ->
      spinner = tElem.find '.spinner'
      for i in [1..13]
        bar = angular.element "<div class=\"spinner-bar-#{i}\"></div>" 
        bar.css('-webkit-transform', "rotate(#{360 * i / 13}deg) translate(0, -142%)")
        spinner.append bar
      (scope, elem, attrs, PanoramaCtrl) ->
        scope.$on 'pano.loading', -> scope.loading = true
        scope.$on 'pano.load', -> scope.loading = false
    controller: ['$scope', ($scope) ->
      $scope.loading = true
    ]
  ]

  cwut.directive 'panorama',
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
