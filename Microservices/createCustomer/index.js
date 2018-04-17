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

//create a Stripe customer w/ card on file
exports.createCustomer = app.get("/:email/:tok", function createCustomer(req, res) {
    var customer = stripe.customers.create({
        email: req.params.email,
        card: req.params.tok,
    }, function(err, customer) {
        if (err) {
            return res.send(JSON.stringify(err));
        }
        res.send(customer);
    });
});