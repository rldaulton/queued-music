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
 * Retrieves a blob of events you can designate with codes for display in 
 * the admin dashboard.
 *
 * In my example, the codes are as follows:
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
 * This function is specifically designed just to look for data needed
 * in the 'customers' graph on iPad dashboard (requests, votes, check ins)
 */

exports.getEventTotals = app.get("/:accountId", function getEventTotals(req, res) {

    let orgId = req.params.accountId;

    var query = [];

    query.push("SELECT event_code, COUNT(event_code) FROM [queuedmusic-d9167:eventLogging.events]");

    if (orgId) {
        query.push('WHERE');
        query.push("(event_code = '100'");
        query.push("OR event_code = '101'");
        query.push("OR event_code = '200'");
        query.push("OR event_code = '201'");
        query.push("OR event_code = '400') AND");
        query.push(`user_org= '${orgId}'`);
    }

    query.push('GROUP BY event_code LIMIT 1000');

    query = query.join(' ');

    bigquery.query(query).then((results) => {
            const rows = results[0];
            res.send(JSON.stringify(rows));
        })
        .catch((err) => {
            return res.send(JSON.stringify(err));
        });
});