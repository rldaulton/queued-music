/*
* A Spotify Authorization Code Flow, used specifically for Android. 
* I have been trying to do a refresh token in an android client, but I 
* notice that when a user logs in using Spotify's SDK, they do not 
* receive a refresh_token. I do not want my users to have to log in every
* time they use the app.
* 
* After finding this issue: 
*
* https://github.com/spotify/android-sdk/issues/259
*
* ...Decided to make my own solution using stateless Google Cloud Functions
* and using: https://github.com/thelinmichael/spotify-web-api-node
*
* It's a bit hacky right now, but it does the job.
* 
* -Ryan
* -Red Shepard Software
*
* Oh yea, license MIT. Use this however the hell you want.
*/

var app = require('express')();
var SpotifyWebApi = require('spotify-web-api-node');
var bodyParser = require('body-parser');

/*
* MARK: - Invocation
* Using an HTTP Trigger, hitting your cloud endpoint, just
* include ".../your_code" at the end of the url.
*
* Pass in EITHER your Authorization Code OR a refresh_tok.
*
* This function extracts it, checks if it is a CODE or
* an refresh token, then re-authenticates and sends back
* new refresh & access tokens.
*/

exports.spotifyAuth = app.get("/:code", function auth (req,res){

  var code = req.params.code;

  var credentials = {
    clientId : 'your_client_id',
    clientSecret : 'your_client_secret',
    redirectUri : 'http//:some_redirect_url'
  };

  var spotifyApi = new SpotifyWebApi(credentials);
  
  // MARK: - CODE Check
  // Spotify authorization code is a 131 char code.
  // A refresh_token is a 239 char code.
  // Simple check to determine which has been passed in.
  
  if (code.length > 131) {
    // Retrieve an access token and a refresh token
    spotifyApi.authorizationCodeGrant(code)
      .then(function(data) {
      
        // If you need to log these, uncomment:
        // console.log('The token expires in ' + data.body['expires_in']);
        // console.log('The access token is ' + data.body['access_token']);
        // console.log('The refresh token is ' + data.body['refresh_token']);
      
        res.contentType('application/json');
        res.send(JSON.stringify(data));
      
      }, function(err) {
        console.log('Authorization Code Grant Flow ERROR: ', err);
    });
  } else {
    spotifyApi.setRefreshToken(code);
    spotifyApi.refreshAccessToken()
      .then(function(refdata) {
      
        // returns JSON values:
        // "access_token": "NgA6ZcYI...ixn8bUQ",
        // "token_type": "Bearer",
        // "scope": "[requested_scope]..",
        // "expires_in": "somedate"
      
        res.contentType('application/json');
        res.send(JSON.stringify(refdata));
      
      }, function(err) {
        console.log('Could not refresh the token!', err.message);
      });
  }

});