var app = require('express')();
var http = require('http').Server(app);
var bodyParser = require('body-parser');

app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json());


var stripe = require("stripe")(
    "sk_live_my-stripe-key"
);

exports.escrowTransfers = app.get("/:accountid", function escrowTransfers(req, res) {

    d = new Date();

    stripe.transfers.list({
            limit: 100,
            destination: req.params.accountid
            //created: { gte: d.getTime() - 604800000 },//.now() -= 604800000
        },
        function(err, transfers) {
            if (err) {
                return res.send(JSON.stringify(err));
            }
            res.send(JSON.stringify(transfers));
        }
    );
});