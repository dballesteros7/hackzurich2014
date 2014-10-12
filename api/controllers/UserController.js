/**
 * UserController
 *
 * @description :: Server-side logic for managing users
 * @help        :: See http://links.sailsjs.org/docs/controllers
 */


module.exports = {
  notes: function(req, res) {
    EvernoteService.listNotes(function(err, notes) {
      if(err){
        console.log(err);
        return res.serverError(err);
      }
      return res.json({
        notes: notes
      });
    });
  },
  notebooks: function (req, res) {
    EvernoteService.listNotebooks(function(err, notes) {
      if(err){
        console.log(err);
        return res.serverError(err);
      }
      return res.json({
        notebooks: notes
      });
    });

  }
};
