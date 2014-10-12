'use strict';

var CreateNoteCtrl = function($scope, $http) {
  this.scope_ = $scope;
  this.http_ = $http;
  $scope.upload = this.upload.bind(this);
  $scope.selectNote = this.selectNote.bind(this);

  $http({
    method: 'GET',
    url: '/user/notes'
  }).then(function(result) {
    $scope.availableNotes = result.data.notes;
  });

  this.selectedNote = null;
};

CreateNoteCtrl.$inject = ['$scope', '$http'];

CreateNoteCtrl.prototype.upload = function($event) {
  $event.preventDefault();
  this.http_({
    method: 'POST',
    url: '/augmentednote',
    data: {
      imageBlob: this.scope_.imageBlob.base64,
      noteGuid: this.scope_.selectedNote.guid
    }
  });
};

CreateNoteCtrl.prototype.selectNote = function(index) {
  if (this.selectedNote !== null) {
    this.selectedNote.selected = false;
  }
  this.selectedNote = this.scope_.availableNotes[index];
  this.selectedNote.selected = true;
  this.scope_.selectedNote = this.selectedNote;
};


angular.module('yarnApp', ['naif.base64']).
controller('CreateNoteCtrl', CreateNoteCtrl);
