'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');

var app = require('express')();
var http = require('http').Server(app);
var bodyParser = require('body-parser');
var Promise = require('promise');
var async = require('async');

var sg = require('sendgrid')(
    'SG.my-sendgrid-key'
);

app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json());

var serviceAccount = require('./serviceAccount.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://my-firebase-database-url"
});

// Sends an email confirmation when a user signs up for the app
exports.sendEmailConfirmation = functions.database.ref('/user/{uid}/email').onWrite(event => {

    if (event.data.previous.exists()) {
        return
    } // If data previously existed, don't resend the welcome email
    if (!event.data.val()) {
        return
    } // If no email, user is 'Guest' - does not get welcome email

    const userEmail = event.data.val();
    var userPic;

    var db = admin.database();

    db.ref(`/user/${event.params.uid}/photoUrl`).once("value", function(pic) {
        // Get user's photo for welcome email.
        userPic = pic.val();
    });


    var request = sg.emptyRequest({
        method: 'POST',
        path: '/v3/mail/send',
        body: {
            personalizations: [{
                to: [{
                    email: userEmail,
                }, ],
                'substitutions': {
                    '-userPic-': userPic
                },
                subject: "Welcome to Queue'd",
            }, ],
            from: {
                email: 'no-reply@my-site.com',
                name: "My-App-Name"
            },
            content: [{
                type: 'text/html',
                value: '.',
            }, ],
            'template_id': 'my-sendgrid-template-id',
        },
    });

    sg.API(request, function(error, response) {
        if (error) {
            console.log('Error response received:' + error);
        }
    });
});