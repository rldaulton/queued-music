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

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

//create a Stripe Connect managed account
exports.createManagedCustomer = app.post("/registerVenue", function createManagedCustomer (req,res){

  stripe.accounts.create({
    type: 'custom',
    country: 'US',
    email: req.body.email,
    business_name: req.body.business_name,
    default_currency: req.body.default_currency,
    external_account: req.body.external_account,
    legal_entity: req.body.legal_entity,
    payout_schedule: req.body.payout_schedule,
    tos_acceptance: req.body.tos_acceptance
  }, function(err, account) {
        if(err) {
        return res.send(JSON.stringify(err));
      }    
      res.send(account);
  });
});