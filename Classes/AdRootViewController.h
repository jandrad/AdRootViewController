//
//  AdRootViewController.h
//  iAdsTest
//
//  Created by Jose Andrade on 2/1/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "AdMobDelegateProtocol.h"

enum
{
	kAdBannerPositionTop = 0,
	kAdBannerPositionBottom,
};

@protocol AdViewControllerDelegate;

@interface AdRootViewController : UIViewController <ADBannerViewDelegate, AdMobDelegate> 
{	
	id <AdViewControllerDelegate>__weak	adDelegate;
	
	//Banners:
	id								adBannerView;	
	AdMobView*						adMobAd;
    
    //Banner Position
    char                            adBannerPosition;
    
    BOOL                            adBannerViewIsVisible;
}

@property (nonatomic, assign) id <AdViewControllerDelegate> adDelegate;
@property(nonatomic, readwrite, assign) char adBannerPosition;

- (void)addBannerAd;
- (void)removeBannerAd;

- (void)rotateBannerViewWithDirector:(UIDeviceOrientation)toDeviceOrientation;
- (void)updateBannerViewOrientationWithDirector;

- (void)rotateBannerViewWithUIViewController:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)updateBannerViewOrientationUIViewController;

@end

@protocol AdViewControllerDelegate

@optional
- (void)adController:(AdRootViewController*)controller didLoadiAd:(id)iadBanner;
- (void)adController:(AdRootViewController*)controller didFailedToRecieveiAd:(id)iadBanner;

- (void)adController:(AdRootViewController*)controller didLoadAdMobAd:(AdMobView*)adMobBanner;
- (void)adController:(AdRootViewController*)controller didFailedToRecieveAdMobAd:(AdMobView*)adMobBanner;

@end
