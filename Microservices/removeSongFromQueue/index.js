'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');

var app = require('express')();
var http = require('http').Server(app);
var bodyParser = require('body-parser');
var Promise = require('promise');
var async = require('async');

app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json());

var serviceAccount = require('./serviceAccount.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://my-firebase-database-url"
});

// Remove a song from the queue once it reaches a certain threshold

exports.removeFromQueue = functions.database.ref('/queue/{venueUid}/{trackURI}/voteCount').onWrite(event => {

    if (parseInt(event.data.val(), 10) > -11) {
        return
    }

    // Delete Queue item if more 
    // than 10 negative votes...

    // Get a database reference
    var db = admin.database();
    var ref = db.ref(`/queue/${event.params.venueUid}/${event.params.trackURI}`);
    ref.remove();
});