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
      template: '<div ng-click="onclick()" ng-style="{left: x, top: y, \'margin-left\': offset}" ng-class="{\'active\': active}" ng-show="markerOnScreen" ng-transclude></div>'
      scope:
        markerPosition: '='
        markerOnScreen: '='
      require: '^panorama'
      transclude: true
      replace: true
      link: (scope, elem, attrs, PanoramaCtrl) ->
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
      template: '<div panorama><div marker data-marker-position="marker" data-marker-on-screen="marker.visible" ng-repeat="marker in markers"></div></div>'
      controller: ['$scope', 'MARKERS', ($scope, MARKERS) ->
          $scope.markers = MARKERS
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
      controller: ['Panorama', (Panorama) ->
        new Panorama()
      ]
      link: (scope, elem, attrs) ->
        elem.append Renderer.domElement
  ]
