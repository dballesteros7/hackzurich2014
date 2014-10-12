// EvernoteService.js in api/services
var sprintf = require('sprintfjs');

var Evernote = require('evernote').Evernote;

var client = new Evernote.Client({
  token: sails.config.evernote.devToken
});
var noteStore = client.getNoteStore();
var userStore = client.getUserStore();

var baseString = 'evernote:///view/%d/%s/%s/%s/';

module.exports = {
  listNotebooks: function(cb) {
    noteStore.listNotebooks(cb);
  },
  listNotes: function(cb) {
    var filter = new Evernote.NoteFilter;
    filter.notebookGuid = '6809d1e3-7bc5-4419-8d2f-36f9a7fb5016';
    var notesMetadataResultSpec = new Evernote.NotesMetadataResultSpec;
    notesMetadataResultSpec.includeTitle = true;
    notesMetadataResultSpec.includeCreated = true;
    notesMetadataResultSpec.includeUpdated = true;
    noteStore.findNotesMetadata(filter, 0, 100, notesMetadataResultSpec, function(err, result) {
      if (err) {
        cb(err);
      } else {
        userStore.getUser(function(err, user) {
          if (err) {
            cb(err);
          } else {
            userStore.getPublicUserInfo(user.username, function(err, publicUser) {
              if (err) {
                cb(err);
              } else {
                for (var i = 0; i < result.notes.length; i++) {
                  var note = result.notes[i];
                  note.url = sprintf(baseString, publicUser.userId, publicUser.shardId, note.guid, note.guid);
                }
                cb(null, result.notes);
              }
            });
          }
        });
      }
    });
  },
  getNoteInfo: function(guid, cb) {
    noteStore.getNote(guid, true, false, false, false, function(err, result) {
      if (err) {
        cb(err);
      } else {
        userStore.getUser(function(err, user) {
          if (err) {
            cb(err);
          } else {
            userStore.getPublicUserInfo(user.username, function(err, publicUser) {
              if (err) {
                cb(err);
              } else {
                var url = sprintf(baseString, publicUser.userId, publicUser.shardId, result.guid, result.guid);
                cb(null, {
                  title: result.title,
                  content: result.content,
                  url: url
                });
              }
            });
          }
        });

      }
    });
  }
};
