/**
 * HTTP Cloud Function.
 *
 * @param {Object} req Cloud Function request context.
 * @param {Object} res Cloud Function response context.
 */
var app = require('express')();
var http = require('http').Server(app);
var stripe = require('stripe')(
    "sk_live_my-stripe-key"
);
var bodyParser = require('body-parser');
var Promise = require('promise');
var async = require('async');

app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json());

//create a customer w/ card on file
exports.accountBalance = app.get("/:accountId", function accountBalance(req, res) {

    if (req.params.accountId) {
        var balance = stripe.balance.retrieve({
            stripe_account: req.params.accountId
        }, function(err, balance) {
            if (err) {
                return res.send(JSON.stringify(err));
            }
            res.send(balance);
        });
    };
});