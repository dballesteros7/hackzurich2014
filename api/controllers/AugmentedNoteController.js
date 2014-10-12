/**
 * AugmentedNoteController
 *
 * @description :: Server-side logic for managing Augmentednotes
 * @help        :: See http://links.sailsjs.org/docs/controllers
 */

module.exports = {
  notes: function(req, res) {
    var params = req.params.all();
    AugmentedNote.find({
      where: {
        noteGuid: params.noteGuid,
        vuforiaCloudId: params.vuforiaCloudId
      },
      limit: 1
    }).exec(function(error, data) {
      EvernoteService.getNoteInfo(data[0].noteGuid, function(err, result) {
        if (err) {
          return res.serverError(err);
        }
        return res.json(result);
      });
    });

  }
};
