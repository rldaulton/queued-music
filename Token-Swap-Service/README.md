Spotify Token Swap Service for Heroku
=======

To use the new [Spotify SDK](https://github.com/spotify/ios-sdk) we are required to run our own [Token Exchange Service](https://developer.spotify.com/technologies/spotify-ios-sdk/tutorial/#setting-up-your-token-exchange-service). This repository provides you with an easy installation on [Heroku](http://heroku.com/home). The current `CLIENT_ID`, `CLIENT_SECRET` and `CLIENT_CALLBACK_URL` are straight from [Spotifys Repo](https://github.com/spotify/ios-sdk/tree/master/Demo%20Projects) and work with their example apps. 


Setup
=======

* Sign up for [Heroku](https://signup.heroku.com/) and follow the first two [Getting Started Steps](https://devcenter.heroku.com/articles/getting-started-with-ruby#introduction)

Unless you are expecting **massive** traffic, the free plan will work for you. Be patient, it can take up to 60 min until you get the confirmation Mail from Heroku.

* [Clone](https://devcenter.heroku.com/articles/getting-started-with-ruby#prepare-the-app) this Repository

```bash
git clone https://github.com/simontaen/SpotifyTokenSwap.git
cd SpotifyTokenSwap
```

From here on forward it's basically following the Getting Started Guide.

* [Deploy](https://devcenter.heroku.com/articles/getting-started-with-ruby#deploy-the-app) the app using git

```bash
heroku create --http-git
git push heroku master
heroku ps:scale web=1
```

* [View logs](https://devcenter.heroku.com/articles/getting-started-with-ruby#view-logs)

```bash
heroku logs --tail
```

* Verify its running

```bash
curl https://peaceful-sierra-1249.herokuapp.com
```

and you should get a `<h1>Not Found</h1>` back. Also check the logs should show something like

```
app[web.1]: ip-10-147-165-35.ec2.internal - - [<timestamp>] "GET / HTTP/1.1" 404 18
app[web.1]: - -> /
app[web.1]: <your-ip> - - [<timestamp>] "GET / HTTP/1.1" 404 18 0.0005
heroku[router]: at=info method=GET path="/" host=peaceful-sierra-1249.herokuapp.com <...>
```

Or run the Spotify examples with a corrected `kTokenSwapServiceURL` and `kTokenRefreshServiceURL`.

* Your own app

As mentioned above the current code is configured to what Spotify provided us. So you need to syncronize the `CLIENT_ID`, `CLIENT_SECRET` and `CLIENT_CALLBACK_URL` between your [Spotify Account](https://developer.spotify.com/my-applications/#!/applications), your iOS App and the `spotify_token_swap.rb`.


Run Locally
=======

```bash
bundle install
foreman start
```

`foreman`is part of the [Heroku Toolbelt](https://devcenter.heroku.com/articles/getting-started-with-ruby#set-up).


Convenience
=======

I personally will host an instance on Heroku for public use as it is very annoying to go through setting everything up when you just want to try something with the SDK. I'll keep it on the free plan and won't pay much attention to it. We'll see how it goes but if the service it getting slammed it'll crash, so be polite.

```
https://peaceful-sierra-1249.herokuapp.com/swap
https://peaceful-sierra-1249.herokuapp.com/refresh
```
