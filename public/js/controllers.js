var asgeirApp = angular.module('asgeirApp', []);

// asgeirApp.controller('TaskListCtrl', function ($scope) {
//   $scope.tasks = [
// 	    {'title': 'Nexus S'},
// 	    {'title': 'Motorola XOOM with Wi-Fi'},
// 	    {'title': 'MOTOROLA XOOM'}
// 	  ];
// });

asgeirApp.controller('TaskListCtrl', function ($scope, $http) {
	$scope.currentTaskId = null;
	$scope.error = '';

	loadTasks();

	$scope.init = function(currentTaskId) {
		if (currentTaskId) {
			$scope.currentTaskId = currentTaskId;
		}
	}

	$scope.clearError = function() {
		$scope.error = '';
	}

  $scope.setCurrentTask = function(taskId) {
  	var taskIdInt = parseInt(taskId);
  	if ((isNaN(taskIdInt)) || (taskIdInt <= 0)) {
	  	$scope.error = 'Task id is not valid: ' + taskId;
	  } else {
	  	$http.post('task/start/' + taskIdInt).success(function(data) {
		    $scope.currentTaskId = taskIdInt;
		  }).error(function(data) {
	  		$scope.error = 'Failed to set current task :(';
	  	})
	  }
  }

  $scope.resetInProgress = function() {
  	$scope.currentTaskId = null;
  	$http.post('task/stop/dummy').success(function(data) {
	    loadTasks();
	  }).error(function(data) {
  		$scope.error = 'Failed to set current task :(';
  	})
  }

  function loadTasks() {
  	$http.get('user/tasks').success(function(data) {
	    $scope.tasks = data.tasks;
	  });
  }
});
