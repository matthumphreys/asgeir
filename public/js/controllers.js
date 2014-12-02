var asgeirApp = angular.module('asgeirApp', []);

asgeirApp.controller('TaskListCtrl', function ($scope, $http) {
	$scope.user = null;
	$scope.currentTaskId = null;	// For this user
	$scope.currentTaskPriority = 0;
	$scope.tasks = [];
	$scope.messages = [];
	$scope.draftMessage = '';
	$scope.error = '';
	// Private
	$scope._eventSource = new EventSource('/stream');

	$scope.init = function(userId, userHandle, currentTaskIdStr, currentTaskPriority) {
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
			if (parsedData.entity_type == 'message') {
				appendMessage(parsedData.entity_data);
			}
		};
		loadTasks();
	}

	$scope.submitOnEnter = function(keyEvent) {
	  if (keyEvent.keyIdentifier === "Enter") {
	    $scope.sendMessage();
	  }
	}

	$scope.sendMessage = function() {
		var message = {
			from_user: $scope.user.id,
			task_id: $scope.currentTaskId,
			msg: $scope.draftMessage
		}
		$http.post('/api/messages/send/', message).success(function(data) {
	    // $scope.$apply(function () {
	    // 	task.draftMessage = '';
	    // });
	  }).error(function(data) {
  		$scope.error = 'Failed to send message :-(';
  	});
  	$scope.draftMessage = '';
	}

	function appendMessage(messageObj) {
		if (messageObj.task.priority >= $scope.currentTaskPriority) {
			$scope.messages.push(messageObj);
			// Let angular know that data has changed
			$scope.$apply(function () {
				$scope.messages = $scope.messages;
			});
			$scope.scrollToLastMessage();
		} else {
			debug("Message priority too low");
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
	  	$http.post('api/tasks/start/' + taskIdInt).success(function(data) {
		    $scope.currentTaskId = taskIdInt;
		    $scope.currentTaskPriority = data.current_task.priority;
		    //$scope.tasks = data.tasks;
		    loadTasks();
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
  	$http.get('api/user/tasks').success(function(data) {
	    $scope.tasks = data.tasks;
	  }).error(function(data) {
  		$scope.error = 'Failed to get tasks :-(';
  	});

	  var taskIdStr = $scope.currentTaskId ? $scope.currentTaskId : '';
  	$http.get('api/messages/?current-task-id=' + taskIdStr).success(function(data) {
	    $scope.messages = data.messages;
	    $scope.scrollToLastMessage();
	  }).error(function(data) {
  		$scope.error = 'Failed to get messages :-(';
  	});
  }

  // XXX: Pass this function to $scope.init as callback!
  $scope.scrollToLastMessage = function() {
  	if (jQuery) {
  		var ARBITRARY_BIG_NUMBER = 10000;
  		jQuery(".msg-list").scrollTop(ARBITRARY_BIG_NUMBER);
  	}
  }

  function debug(str) {
  	console.log(str);
  }

});
