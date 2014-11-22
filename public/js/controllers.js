var asgeirApp = angular.module('asgeirApp', []);

asgeirApp.controller('TaskListCtrl', function ($scope, $http) {
	$scope.user = null;
	$scope.currentTaskId = null;	// For this user
	$scope.error = '';
	// Private
	$scope._eventSource = new EventSource('/stream');

	loadTasks();

	$scope.init = function(userId, userHandle, currentTaskIdStr) {
		$scope.user = {
			id: userId,
			handle: userHandle,
			// TODO: Avatar
		};
		if (currentTaskIdStr) {
			$scope.currentTaskId = parseInt(currentTaskIdStr);
		}
		$scope._eventSource.onmessage = function(e) {
			console.log('DEBUG:' + e.data);
			var parsedData = JSON.parse(e.data);
			if (parsedData.entityType == 'message') {
				appendMessage(parsedData.entityData);
			}
		};
	}

	$scope.submitOnEnter = function(keyEvent, task) {
	  if (keyEvent.keyIdentifier === "Enter") {
	    $scope.sendMessage(task);
	  }
	}

	$scope.sendMessage = function(task) {
		var message = {
			from_user: $scope.user.id,
			task_id: task.id,
			msg: task.draftMessage
		}
		$http.post('/api/messages/send/', message).success(function(data) {
	    // $scope.$apply(function () {
	    // 	task.draftMessage = '';
	    // });
	  }).error(function(data) {
  		$scope.error = 'Failed to send message :-(';
  	});
  	task.draftMessage = '';
	}

	function appendMessage(messageObj) {
		var targetTask = _.findWhere($scope.tasks, {id: messageObj.taskId});
		if (targetTask) {
			if (typeof targetTask.messages === 'undefined') {
				targetTask.messages = [];
			}
			targetTask.messages.push(messageObj);
			// Let angular know that data has changed
			$scope.$apply(function () {
				$scope.tasks = $scope.tasks;
			});
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
	  		$scope.error = 'Failed to set current task :-(';
	  	});
	  }
  }

  $scope.resetInProgress = function() {
  	$scope.currentTaskId = null;
  	$http.post('task/stop/dummy').success(function(data) {
	    loadTasks();
	  }).error(function(data) {
  		$scope.error = 'Failed to set current task :-(';
  	});
  }

  function loadTasks() {
  	$http.get('user/tasks').success(function(data) {
	    $scope.tasks = data.tasks;
	  });
	  // TODO: .error
  }

});
