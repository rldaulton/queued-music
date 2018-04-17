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

/**
 * Triggers when a user's requested song begins to play. We tell them their selection
 * is now playing.
 *
 * Items in the playing queue have 'playing' param. This is triggered on change to `true`.
 * Users save their device notification tokens to `/user/{userid}/FCMToken`.
 */

exports.sendRequesterNotification = functions.database.ref('/queue/{venueUid}/{trackURI}/playing').onWrite(event => {

    const venueUid = event.params.venueUid;
    const trackURI = event.params.trackURI;
    // If 'false', do not execute.
    if (!event.data.val() == true) {
        return
    }
    var us_er = '';
    var token = '';
    var db = admin.database();

    var refUser = db.ref(`/queue/${event.params.venueUid}/${event.params.trackURI}/addedBy`);
    var refTrack = db.ref(`/queue/${event.params.venueUid}/${event.params.trackURI}/trackName`);
    var refArtist = db.ref(`/queue/${event.params.venueUid}/${event.params.trackURI}/trackArtist`);
    var refVenue = db.ref(`/venue/${event.params.venueUid}/name`);

    const un = refUser.once("value", function(usr) {
        // Get user who submitted the track request.
        us_er = usr.val();
    });

    const du = refTrack.once("value");

    const tre = refArtist.once("value");

    const qua = refVenue.once("value");

    return Promise.all([un, du, tre, qua]).then(results => {
        const trackSubmittedBy = results[0];
        const trackPlaying = results[1];
        const artistPlaying = results[2];
        const playingAtVenue = results[3];


        db.ref(`/user/${us_er}/FCMToken`).once("value", function(tok) {
            if (!tok.val()) {
                return
            }
            token = tok.val();

            // Notification details.
            const payload = {
                notification: {
                    title: `'${trackPlaying.val()}' by ${artistPlaying.val()}`,
                    body: `${playingAtVenue.val()} is now playing your request.`,
                }
            };

            // Send notifications to all tokens.
            return admin.messaging().sendToDevice(token, payload).then(response => {
                // For each message check if there was an error.
                const tokensToRemove = [];
                response.results.forEach((result, index) => {
                    const error = result.error;
                    if (error) {
                        console.error('Failure sending notification to', tokens[index], error);
                        // Cleanup the tokens who are not registered anymore.
                        if (error.code === 'messaging/invalid-registration-token' ||
                            error.code === 'messaging/registration-token-not-registered') {
                            tokensToRemove.push(tokensSnapshot.ref.child(tokens[index]).remove());
                        }
                    }
                });
                return Promise.all(tokensToRemove);
            });
        });
    });
});