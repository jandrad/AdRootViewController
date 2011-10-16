AdRootViewController
==================

RootViewController replacement for Cocos2d that supports iAds and AdMob.


Features
-------------

   * Two Positions to set the Ads (Top, or Bottom)
   * Autorotation support, using CCDirector or UIViewController
   * Universal support (iPhone + iPad)
   * Interstitial ads (AdMob Only)
   * Easy to use


Usage
-----------------------

Replace the RootViewController in the Cocos2d project with the AdRootViewController.

Define your AdMob publisher Id

    #define ADMOB_PUBLISHER_ID @"your_publisher_id"

To add the ad to the controller's view call:

    [viewController addBannerAd];

To remove the ad call: 

    [viewController removeBannerAd];

Interstitial Ads are shown calling:

    [viewController addInterstitialAd];

You can set the position of the ad at the Top or Bottom of the Screen, just call:

    [viewController setAdBannerPosition:kAdBannerPositionBottom] 

or 

    [viewController setAdBannerPosition:kAdBannerPositionTop]


Hope it helps, suggestions and corrections are always welcome.