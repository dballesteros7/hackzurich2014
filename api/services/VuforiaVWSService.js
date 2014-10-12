// VuforiaVWSService.js - in api/services

// UUIDs in Node
var uuid = require('node-uuid');

// Request - Simple HTTP
var request = require('request');

// Vuforia VWS API SDK
var vuforia = require('vuforiajs');

// init client with secrets credentials
var client = vuforia.client({
  accessKey: sails.config.vuforia.serverAccessKey,
  secretKey: sails.config.vuforia.serverSecretKey
});

// util for base64 encoding and decoding
var util = vuforia.util();

module.exports = {
  addVuforiaTarget: function(options, cb) {
    var target = {
      name: uuid.v4(),
      width: 32.0,
      image: options.imageBlob,
      active_flag: true,
      application_metadata: util.encodeBase64(options.noteGuid)
    };
    client.addTarget(target, function(error, result) {
      if (error) {
        console.error(result);
        cb(error);
      } else {
        cb(null, target.name);
      }
    });
  }
};
