# FSNetworkingSearchController

[![Join the chat at https://gitter.im/alexruperez/FSNetworkingSearchController](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/alexruperez/FSNetworkingSearchController?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Twitter](http://img.shields.io/badge/contact-@alexruperez-blue.svg?style=flat)](http://twitter.com/alexruperez)
[![GitHub Issues](http://img.shields.io/github/issues/alexruperez/FSNetworkingSearchController.svg?style=flat)](http://github.com/alexruperez/FSNetworkingSearchController/issues)
[![CI Status](http://img.shields.io/travis/alexruperez/FSNetworkingSearchController.svg?style=flat)](https://travis-ci.org/alexruperez/FSNetworkingSearchController)
[![Version](https://img.shields.io/cocoapods/v/FSNetworkingSearchController.svg?style=flat)](http://cocoapods.org/pods/FSNetworkingSearchController)
[![License](https://img.shields.io/cocoapods/l/FSNetworkingSearchController.svg?style=flat)](http://cocoapods.org/pods/FSNetworkingSearchController)
[![Platform](https://img.shields.io/cocoapods/p/FSNetworkingSearchController.svg?style=flat)](http://cocoapods.org/pods/FSNetworkingSearchController)
[![Dependency Status](https://www.versioneye.com/user/projects/555b0412634daacd4100019e/badge.svg?style=flat)](https://www.versioneye.com/user/projects/555b0412634daacd4100019e)
[![Analytics](https://ga-beacon.appspot.com/UA-55329295-1/FSNetworkingSearchController/readme?pixel)](https://github.com/igrigorik/ga-beacon)


## Overview

Search controller with suggest completion using Foursquare API following Instagram design.

![FSNetworkingSearchController Screenshot](https://raw.githubusercontent.com/alexruperez/FSNetworkingSearchController/master/screenshot.gif)

### Installation

FSNetworkingSearchController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "FSNetworkingSearchController"

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Usage

#### FSNetworkingSearchController

Call `+ (void)configureWithClientID:(NSString *)clientID clientSecret:(NSString *)clientSecret redirectURI:(NSString *)redirectURI`

```objectivec
[FSNetworkingSearchController configureWithClientID:@"YOUR_CLIENT_ID" clientSecret:@"YOUR_CLIENT_SECRET" redirectURI:@"YOUR_REDIRECT_URI"];
```

If you need to login for accurated results call `+ (void)loginWithCompletion:(FSNSCAccessTokenBlock)completion` and put `+ (BOOL)handleOpenURL:(NSURL *)handledURL` in your `- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation`

```objectivec
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FSNetworkingSearchController handleOpenURL:url];
}

[FSNetworkingSearchController loginWithCompletion:^(NSString *accessToken, NSError *error) {
    NSLog(@"DO STUFF");
}];
```

FSNetworkingSearchController automatically gets the user location if you don't already do it, only put `NSLocationWhenInUseUsageDescription` key in your plist. But you could force to use a custom CLLocation with the method `+ (void)forceLocation:(CLLocation *)location`, for example if you what to use the metadata of an image.

#### FSNetworkingViewHandler

Use it as your UISearchDisplayController delegate, UISearchController searchResultsUpdater or your UITableView dataSource and delegate. Your could do it programmatically or using the storyboard like in the example project. Have IBInspectable properties.

You could customize it or set the selectHandler to detect selected Foursquare Venue.

#### FSNetworkingCommunicator

I use [foursquare](https://github.com/foursquare)/[FSNetworking](https://github.com/foursquare/FSNetworking) to make the API requests, but it's a protocol, you can inject your own to the FSNetworkingSearchController or mock it if you need.

# Etc.

* Contributions are very welcome.
* Attribution is appreciated (let's spread the word!), but not mandatory.

## Use it? Love/hate it?

Tweet the author [@alexruperez](http://twitter.com/alexruperez), and check out alexruperez's blog: http://alexruperez.com

## License

FSNetworkingSearchController is available under the MIT license. See the LICENSE file for more info.
