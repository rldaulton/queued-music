'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({
    origin: true
});

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

/* CORS */
app.use(function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    res.header("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE, OPTIONS");
    next();
});

/**
 * For Venues to send custom push notification to all users who are checked in
 * Requirea a JSON object to be posted to the function:
 *  {
 *    "title" : "...",
 *    "body" : "...",
 *    "userid" : "...",
 *    "venueid" : "..."
 *  }
 */

exports.sendPushMsg = functions.https.onRequest((req, res) => {

    cors(req, res, () => {
        const title = req.body.title;
        const body = req.body.body;
        const userId = req.body.userid;
        const orgId = req.body.venueid;

        return loadUsers(orgId, userId).then(users => {
            let tokens = [];
            if (userId == null) {
                for (let user of users) {
                    tokens.push(user.FCMToken);
                }
            } else {
                for (let user of users) {
                    tokens.push(user);
                }
            }

            let payload = {
                notification: {
                    title: title,
                    body: body,
                    sound: 'default'
                }
            };
            return admin.messaging().sendToDevice(tokens, payload).then(() => {
                res.status(200).send('ok');
            }).catch(err => {
                console.log(err.stack);
                res.status(500).send('error');
            });
        });
    });
});

function loadUsers(org, userId) {

    if (userId == null) {
        //console.log('null userId: send to all');
        var dbRef = admin.database().ref(`/check_ins/${org}`);
        let defer = new Promise((resolve, reject) => {
            dbRef.once('value', (snap) => {
                let data = snap.val();
                //console.log(data);
                let users = [];
                for (var property in data) {
                    users.push(data[property]);
                }
                resolve(users);
            }, (err) => {
                reject(err);
            });
        });
        return defer;
    } else {
        var dbRef = admin.database().ref(`/check_ins/${org}/${userId}`);
        let defer = new Promise((resolve, reject) => {
            dbRef.once('value', (snap) => {
                let data = snap.val();
                //console.log(data);
                let users = [];
                for (var property in data) {
                    if (property == 'FCMToken') {
                        users.push(data[property]);
                    }
                }
                resolve(users);
            }, (err) => {
                reject(err);
            });
        });
        return defer;
    }
}