![logo](Repo-Assets/queued.png)
<p align="center"> 
<img src="Repo-Assets/showcase-gif.gif">
</p>

# Queue'd Music
#### Queue'd is the best way to enjoy music with your friends. Add your favorite songs to a shared music queue at your favorite bars, restaurants and get-togethers, then vote to decide what plays next.  

Music has an incredible way of setting the tone for any gathering. With Queue'd, the crowd takes control, collectively deciding what songs play, and in what order they are played in. 

Connect with your Spotify account and add music from your favorite playlists, or search for any song you'd like, then add it to the queue with one touch. Vote up or down on any song in the queue, and control the flow of music with the help of those around you.

Read more information [on our website](https://www.redshepardsoftware.com/queued.html).

## What is this?

Queue'd is an application that creates a shared music queue, based on location. A 'venue' — for example, a bar — can create an account using the iPad Admin version of the app. This allows them to set up a location, and create a democratized music queue for others to 'check in' to, and begin adding music. 

The iPhone version of the app is for patrons — in this example, the bargoers. Users can sign in using Spotify, Google, or enter as a Guest. Once 'checked in' to their location of choice, users can see and manipulate the queue by voting, adding songs, or purchasing vote packages to boost their song selections.

## Getting Started

This project is a fully functional system, front to back...well, kinda. I provide the source code for the app on both iPhone and iPad, as well as examples for some backend code that you will need in order to have a fully functional version of the app(s).

For example, the app needs a token exchange service to use the Spotify SDK, and some cloud functions for creating and adding payments and payment methods to Stripe. In addiiton, the app uses Firebase to hold it's real-time, votable queue. Running the code and using the apps will begin to create your schema since Firebase will create nodes where they don't exist previously, if told to do so. However, it is assumed you know how to get a Firebase project up and running, since the app will also require your own `GoogleService-Info.plist` file to properly function. 

You might be asking yourself — _why release this entire system?_ Well, as with everything, there's a [story](https://www.redshepardsoftware.com/blog/open-sourcing.html)...

### Prerequisites
#### IDE
- XCode 9+ (preferrable)
- Swift 3.3+

#### External Products
- Spotify Account
- A Cloud Platform Account (Google, AWS, Azure, etc)
- Firebase Account
- Stripe Account (if you want to enable payments)

It may also be beneficial to have your own website so you can deploy your own version of Terms & Conditions and direct support requests to your domain email.

### Installing

Since this is a full application, the best way to run it and make it your own is to download the `.zip` manually.

## Running The Project

In order to run, you need to get a few things set up. Setup the accounts from the **External Product** section above, then roughly follow these steps:
1. Create a Spotify Developer Account, to fully run the music system you will need Premium. Then, [plug in your client id](https://github.com/rldaulton/queued-music/wiki/Adding-Your-Spotify-Information) to the source code.
2. [Prepare a token exchange service](https://github.com/rldaulton/queued-music/wiki/Adding-Your-Spotify-Information#creating-a-token-swap-service) (I used Heroku) and deploy the ruby files to run your exchange. Plug in your endpoints to the app.
3. Create a Firebase project, include the `GoogleService-Info.plist` file from your project in the app files.
4. Create a Stripe Account, and [include your keys](https://github.com/rldaulton/queued-music/wiki/Adding-Your-Stripe-Information) in the source code. 
5. Using a backend service (I used GCP), [create and deploy the necessary cloud functions](https://github.com/rldaulton/queued-music/wiki/Creating-Your-'Serverless'-Backend) to power Stripe transactions, queue manipulation and more.

## Built With

- [DGElasticPullToRefresh](https://github.com/gontovnik/DGElasticPullToRefresh)
- [BRYXBanner](https://github.com/bryx-inc/BRYXBanner)
- [BusyNavigationBar](https://github.com/gmertk/BusyNavigationBar)
- [Alamofire](https://github.com/Alamofire/Alamofire)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [IQKeyboardManagerSwift](https://github.com/hackiftekhar/IQKeyboardManager)
- [PKHUD](https://github.com/pkluz/PKHUD)
- [AlamofireImage](https://github.com/Alamofire/AlamofireImage)
- [CoreStore](https://github.com/JohnEstropia/CoreStore)
- [BWWalkthrough](https://github.com/ariok/BWWalkthrough)
- [Whisper](https://github.com/hyperoslo/Whisper)
- [AudioIndicatorBars](https://github.com/LeonardoCardoso/AudioIndicatorBars)

## Authors

[Ryan Daulton](https://ryandaulton.com)

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/rldaulton/queued-music/blob/master/LICENSE) file for details

