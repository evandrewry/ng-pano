define ['lib/angular'], (ng) ->
  app = ng.module 'angular.safeApply', []

  app.factory '$safeApply', ['$rootScope', ($rootScope) ->
    ($scope, fn) ->
      phase = $scope.$root.$$phase
      if phase == '$apply' or phase == '$digest'
        $scope.$eval fn if fn
      else
        if fn
          $scope.$apply fn
        else
          $scope.$apply()
  ]
