
var app = require('express')();
var http = require('http').Server(app);
var stripe = require('stripe')(
    "sk_test_my-stripe-key"
);
var bodyParser = require('body-parser');
var Promise = require('promise');
var async = require('async');

app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json());

// Retrieve managed Stripe account
exports.retrieveManaged = app.get("/:acctId", function retrieveManaged(req, res) {

    stripe.accounts.retrieve(
        req.params.acctId,
        function(err, account) {
            if (err) {
                return res.send(JSON.stringify(err));
            }

            res.send(JSON.stringify(account));
        }
    );
});