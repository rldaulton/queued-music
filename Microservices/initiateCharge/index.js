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
var stripe = require('stripe')(
    "sk_live_my-stripe-key"
);
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

/* CORS */
app.use(function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    res.header("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE, OPTIONS");
    next();
});

var appForCharge = app;
appForCharge.get("/:customerid/:source/:amount/:org", (req, res) => {

    let orgId = req.params.org;
    return getVenueAcct(orgId).then(transferAcct => {
        if (transferAcct) {
            var newAmount = Math.round((((req.params.amount - 30) * 0.9725) * 0.3), -2);
            stripe.charges.create({
                customer: req.params.customerid,
                currency: 'usd',
                source: req.params.source,
                amount: req.params.amount,
                destination: {
                    amount: newAmount, // 30% of total - 2.75% fee
                    account: transferAcct
                }
            }, function(err, charge) {
                if (err) {
                    return res.send(JSON.stringify(err));
                }
                res.send(JSON.stringify(charge));
            });
        } else {
            //console.log("No Transfer Account: using defaulf org");
            stripe.charges.create({
                customer: req.params.customerid,
                currency: 'usd',
                source: req.params.source,
                amount: req.params.amount
            }, function(err, charge) {
                if (err) {
                    return res.send(JSON.stringify(err));
                }
                res.send(JSON.stringify(charge));
            });
        }

    });

    function getVenueAcct(org) {
        var dbRef = admin.database().ref(`/venue/${org}/paymentID`);
        let defer = new Promise((resolve, reject) => {
            dbRef.once('value', (snap) => {
                let data = snap.val();
                resolve(data);
            }, (err) => {
                reject(err);
            });
        });
        return defer;
    }

});

//initiate a one-off charge for a customer w/ venue escrow split
exports.initiateCharge = functions.https.onRequest(appForCharge);