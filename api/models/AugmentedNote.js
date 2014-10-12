/**
 * AugmentedNote.js
 *
 * @description :: TODO: You might write a short summary of how this model works and what it represents here.
 * @docs        :: http://sailsjs.org/#!documentation/models
 */

module.exports = {

  attributes: {
    pictureUrl: {
      type: 'string',
      required: true
    },
    noteGuid: {
      type: 'string',
      required: true
    },
    vuforiaCloudId: {
      type: 'string',
      unique: true,
      required: true
    }
  },

  beforeValidate: function(values, cb) {
    console.log( values );
    VuforiaVWSService.addVuforiaTarget(values,
      function(error, result) {
        if (error) {
          console.log(error);
          cb(error);
        } else {
          values.pictureUrl = 'nothing!';
          values.vuforiaCloudId = result;
          cb();
        }
      });
  }
};
