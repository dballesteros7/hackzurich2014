/**
 * AugmentedNoteController
 *
 * @description :: Server-side logic for managing Augmentednotes
 * @help        :: See http://links.sailsjs.org/docs/controllers
 */

module.exports = {
  notes: function(req, res) {
    return res.json({
      url: 'http://www.github.com',
      content: 'From the server!',
      title: 'A note...'
    });
  }
};
