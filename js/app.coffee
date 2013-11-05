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
  "data/data",
  "lib/angular",
  "cs!panorama",
  "cs!$safeApply",
], (data, ng) ->

  cwut = ng.module 'cwut', ['panorama']

  cwut.directive 'marker', ->
    templateUrl: 'templates/marker.html'
    scope:
      markerPosition: '='
      onscreen: '='
      active: '='
    require: '^panorama'
    transclude: true
    replace: true
    link: (scope, elem, attrs, PanoramaCtrl) ->
      scope.ctrl = PanoramaCtrl
      PanoramaCtrl.attach scope, scope.markerPosition

      scope.active = false
      scope.onclick = ->
        scope.active = !scope.active
        scope.$emit 'marker.clicked', scope

  cwut.factory 'MARKERS', ->
    m = new THREE.Vector3(m.x, m.y, m.z) for m in data.markers

  cwut.directive 'markerPano', ->
    templateUrl: 'templates/marker-pano.html'
    controller: ['$scope', 'Panorama', 'MARKERS', ($scope, Panorama, MARKERS) ->
        $scope.markers = MARKERS
        $scope.next = Panorama.nextTexture
        $scope.$on 'marker.clicked', (e, scope) ->
          $scope.marker.active = false if $scope.marker
          $scope.marker = null
          $scope.marker = scope.markerPosition if scope.active
    ]

  cwut.directive 'panoramaSpinner', ->
    require: '^panorama'
    templateUrl: 'templates/spinner.html'
    scope:
      n: "@"
    replace: true
    controller: ['$scope', '$timeout', '$attrs', 'Panorama', ($scope, $timeout, $attrs, Panorama) ->
      $scope.loading = Panorama.loading
      $scope.is = (i for i in [1..(parseInt $attrs.n)])
      $scope.$on 'pano.loading', -> $scope.loading = true
      $scope.$on 'pano.load', -> $timeout (-> $scope.loading = false), 2000
    ]

