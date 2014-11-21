var asgeirApp = angular.module('asgeirAdminApp', []);

asgeirApp.controller('TaskAdminCtrl', function ($scope, $http) {
	$scope.tasks = [];
	$scope.newTask = initNewTask();
	$scope.error = '';

	//init();

	$scope.init = function() {
		$http.get('/api/tasks/').success(function(data) {
	    $scope.tasks = data.tasks;
	  });
	}

	function initNewTask() {
		return {
			title: '',
			priority: 1000
		};
	}

	$scope.clearError = function() {
		$scope.error = '';
	}

	$scope.saveTask = function(myData, isNew) {
		$http.post('/api/tasks/', myData).success(function(data) {
			// Add new task to client-side model
			if (isNew) {
	    	$scope.tasks.push(data.task);
	    }
			// Update order of tasks
	    $scope.tasks = _.sortBy($scope.tasks, function(task) {
	    	return task.priority;
	    });
	    $scope.newTask = initNewTask();
	  })
	  .error(function(data, status) {
	  	$scope.error = 'Failed to save task :(';
	  });
	}

	$scope.deleteTask = function(myData) {
		console.log(myData);
		$http.delete('/api/tasks/' + myData.id).success(function(data) {
			$scope.tasks = _.reject($scope.tasks, function(task) {
				return task.id == myData.id;
			});
		})
		.error(function(data, status) {
	  	$scope.error = 'Failed to delete task :(';
	  });
	}

});
