'use strict';

const logging = require('@google-cloud/logging')();
const bigquery = require('@google-cloud/bigquery')();
const config = require('./config.json');

var app = require('express')();
var http = require('http').Server(app);
var bodyParser = require('body-parser');

app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json());

/* CORS */
app.use(function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    res.header("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE, OPTIONS");
    next();
});

/*
 * You can designate a database, like BigQuery to log special events for in app
 * analytical use (like on the iPad Dashboard):
 *
 * In my example, the codes are as logged as follows:
 *   - 101: user performing a regular upvote on a track/song
 *   - 100: user performing a regular downvote on a track/song
 *   - 201: user performing a Premium upvote on a track/song
 *   - 200: user performing a Premium downvote on a track/song
 *   - 400: user adding a song to the queue
 *   - user purchasing a vote package
 *     - 320: user buys 20 vote package
 *     - 360 user buys 60 vote package
 *     - 3120: user buys 120 vote package
 *
 * This function is specifically designed to log events with the above codes
 * as they are sent from within the client devices.
 */

exports.logEvent = app.post("/", function logE(req, res) {
    const dataset = bigquery.dataset(config.DATASET);
    const table = dataset.table(config.TABLE);

    table.insert([{
            event_code: req.body.event_code,
            event_time: new Date().toJSON(),
            user_id: req.body.user_id,
            event_details_desc: req.body.event_details_desc,
            user_org: req.body.user_org
        }])
        .then(function(data) {
            var apiResponse = data[0];
            console.log(data);
            res.send(JSON.stringify("succeeded"));
        })
        .catch(function(err) {
            console.log(err);
            res.send(JSON.stringify(err));
            // An API error or partial failure occurred.

            if (err.name === 'PartialFailureError') {
                // Some rows failed to insert, while others may have succeeded.

                // err.errors (object[]):
                // err.errors[].row (original row object passed to `insert`)
                // err.errors[].errors[].reason
                // err.errors[].errors[].message
            }
        });
});
