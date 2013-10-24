define ['lib/angular'], (ng) ->
  app = ng.module 'angular.safeApply', []

  app.factory '$safeApply', ['$rootScope', ($rootScope) ->
    ($scope, fn) ->
      phase = $scope.$root.$$phase
      if phase == '$apply' or phase == '$digest'
        $scope.$evalfn if fn
      else
        if fn
          $scope.$apply fn
        else
          $scope.$apply()
  ]
