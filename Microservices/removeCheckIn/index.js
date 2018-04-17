'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({origin: true});

var app = require('express')();
var http = require('http').Server(app);
var bodyParser = require('body-parser');
var Promise = require('promise');
var async = require('async');


app.use(bodyParser.urlencoded({ extended: true }));
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

var appForRemoval = app;
appForRemoval.get("/:customerid/:org", (req, res) => {
  
  let org = req.params.org;
  let user = req.params.customerid;

  var db = admin.database();
  var ref = db.ref(`/check_ins/${org}/${user}`);
  ref.remove();
  res.send(JSON.stringify('ok'));
});

//remove a user from the check_in table
exports.removeCheckIn = functions.https.onRequest(appForRemoval);
