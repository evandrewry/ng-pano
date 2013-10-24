/*
 *  This file is part of the source code for ng-pano, an AngularJS
 *  implementation of an equirectangular panorama viewer. Compatible with
 *  any browser with support for WebGL or HTML5 Canvas.
 *
 *  Copyright © 2013 Evan Drewry
 *  evandrewry@gmail.com
 *  http://deth.ly
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

require.config({
  shim: {
    'lib/angular': {
      deps: ['jquery'],
      exports: 'angular'
    },
    'lib/animation-frame': [],
    'lib/detector': {
      exports: 'Detector'
    },
    'lib/three': {
      exports: 'THREE'
    },
    'lib/tween': {
      exports: 'TWEEN'
    },
  },
  paths: {
    app: 'app',
    'coffee-script': 'lib/coffee-script',
    cs: 'lib/cs',
    jquery: '//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min',
    '$safeApply': 'lib/angular.safe-apply',
  }
});

require(['cs!app', 'lib/angular'], function (app, ng) {
  angular.bootstrap(ng.element('html'), ['cwut']);
});
