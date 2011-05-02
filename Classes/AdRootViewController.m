//
//  AdRootViewController.m
//  iAdsTest
//
//  Created by Jose Andrade on 2/1/11.
//  Copyright Jose Andrade 2011. All rights reserved.
//

//
// RootViewController + iAd
// If you want to support iAd, use this class as the controller of your iAd
//

#import "cocos2d.h"

#import "AdRootViewController.h"
#import "GameConfig.h"
#import "GADBannerView.h"
#import "GADInterstitial.h"

@implementation AdRootViewController

@synthesize adDelegate, adBannerPosition;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        adBannerPosition = kAdBannerPositionTop;
        
#if GAME_AUTOROTATION==kGameAutorotationCCDirector
        //Begin Generating orientation Notifications
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        //Add Observer for autorotarion
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(orientationChanged:) 
                                                     name:UIDeviceOrientationDidChangeNotification 
                                                   object:nil];
#endif
    }
    
    return self;
}

//
// This callback only will be called when GAME_AUTOROTATION == kGameAutorotationCCDirector
//
#if GAME_AUTOROTATION==kGameAutorotationCCDirector
-(void) orientationChanged:(NSNotification *)notification
{	
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	
	if (orientation == (UIDeviceOrientation)[[CCDirector sharedDirector] deviceOrientation])
		return;
	
    
    //Modify this to set the orientation needed using CCDirector
	//if (UIDeviceOrientationIsLandscape(orientation))
	//{
		[[CCDirector sharedDirector] setDeviceOrientation:(ccDeviceOrientation)orientation];
		[self updateBannerViewOrientationWithDirector];
	//}
}
#endif

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	//
	// There are 2 ways to support auto-rotation:
	//  - The OpenGL / cocos2d way
	//     - Faster, but doesn't rotate the UIKit objects
	//  - The ViewController way
	//    - A bit slower, but the UiKit objects are placed in the right place
	//
	
#if GAME_AUTOROTATION==kGameAutorotationNone
	//
	// EAGLView won't be autorotated.
	// Since this method should return YES in at least 1 orientation, 
	// we return YES only in the Portrait orientation
	//
	return ( interfaceOrientation == UIInterfaceOrientationPortrait );
	
#elif GAME_AUTOROTATION==kGameAutorotationCCDirector
	
	// Since this method should return YES in at least 1 orientation, 
	// we return YES only in the Portrait orientation
	return ( interfaceOrientation == UIInterfaceOrientationPortrait );
	
#elif GAME_AUTOROTATION == kGameAutorotationUIViewController
	//
	// EAGLView will be rotated by the UIViewController
	//
	// Sample: Autorotate only in landscpe mode
	//
	// return YES for the supported orientations
	
	return YES;//UIInterfaceOrientationIsLandscape(interfaceOrientation);
	
#else
#error Unknown value in GAME_AUTOROTATION
	
#endif // GAME_AUTOROTATION
	
	
	// Should not happen
	return NO;
}

//
// This callback only will be called when GAME_AUTOROTATION == kGameAutorotationUIViewController
//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	//
	// Assuming that the main window has the size of the screen
	// BUG: This won't work if the EAGLView is not fullscreen
	///
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	CGRect rect;
	
	if(toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)		
		rect = screenRect;
	
	else if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
		rect.size = CGSizeMake( screenRect.size.height, screenRect.size.width );
	
	CCDirector *director = [CCDirector sharedDirector];
	EAGLView *glView = [director openGLView];
	float contentScaleFactor = [director contentScaleFactor];
	
	if( contentScaleFactor != 1 ) 
    {
		rect.size.width *= contentScaleFactor;
		rect.size.height *= contentScaleFactor;
	}
    
	glView.frame = rect;
    
    //Rotate Ad Banner to Interface Orientation
    [self rotateBannerViewWithUIViewController:toInterfaceOrientation];
}
#endif // GAME_AUTOROTATION == kGameAutorotationUIViewController

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) dealloc
{	
    [self removeInterstitialAd];
	[self removeBannerAd];
    [super dealloc];
}

#pragma mark -
#pragma mark Ad Helper Methods

- (void)updateBannerViewOrientationWithDirector
{
	[self rotateBannerViewWithDirector:[[CCDirector sharedDirector] deviceOrientation]];
}

- (void)updateBannerViewOrientationUIViewController
{
    [self rotateBannerViewWithUIViewController:[self interfaceOrientation]];
}

- (void)updateBannerViewOrientation
{
#if ((GAME_AUTOROTATION == kGameAutorotationCCDirector) || (GAME_AUTOROTATION==kGameAutorotationNone))	
	[self updateBannerViewOrientationWithDirector];
#elif GAME_AUTOROTATION==kGameAutorotationUIViewController
    [self updateBannerViewOrientationUIViewController];
#endif
}

- (int)getBannerHeight:(UIInterfaceOrientation)orientation 
{
    return [ADBannerView sizeFromBannerContentSizeIdentifier:[adBannerView currentContentSizeIdentifier]].height;
}

- (int)getBannerHeight 
{
    return [self getBannerHeight:[self interfaceOrientation]];
}

#pragma mark -
#pragma mark Banner Ads Support

- (void)requestAdMobAd
{
    //Initialize admob banner
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        adMobAd = [[GADBannerView alloc] initWithFrame:CGRectMake(0.0,0.0,
                                                                  GAD_SIZE_728x90.width,
                                                                  GAD_SIZE_728x90.height)];
    else
    {
        adMobAd = [[GADBannerView alloc] initWithFrame:CGRectMake(0.0,0.0,
                                                GAD_SIZE_320x50.width,
                                                GAD_SIZE_320x50.height)];
    }
    
    //Set the ad properties
    adMobAd.adUnitID = ADMOB_PUBLISHER_ID;
    adMobAd.rootViewController = self;
    adMobAd.delegate = self;
    
    [self.view addSubview:adMobAd];
    
    //Initialize ad request
    GADRequest *request = [GADRequest request];
    
    //Testing on for the Simulator, it is ignored in devices
    request.testing = YES;
    
    //Request additional parameters, customize ad colors
    request.additionalParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    @"000000", @"color_bg",
                                    @"FFFFFF", @"color_bg_top",
                                    @"FFFFFF", @"color_border",
                                    @"000080", @"color_link",
                                    @"FFFFFF", @"color_text",
                                    @"008000", @"color_url",
                                    nil];
    
    //Load ad request
    [adMobAd loadRequest:request];
}

- (void)addBannerAd
{
    adBannerViewIsVisible = NO;
    
    //Initialize the class manually to make it compatible with iOS < 4.0
    Class classAdBannerView = NSClassFromString(@"ADBannerView");
    if (classAdBannerView != nil) 
    {
        adBannerView = [[classAdBannerView alloc] init];
        [adBannerView setDelegate:self];
        [adBannerView setRequiredContentSizeIdentifiers: [NSSet setWithObjects: 
                                                          ADBannerContentSizeIdentifierPortrait, 
                                                          ADBannerContentSizeIdentifierLandscape, nil]];
        
        CGSize bannerSize = [ADBannerView sizeFromBannerContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        [adBannerView setFrame:CGRectMake(0,0,bannerSize.width,bannerSize.height)];
        
        [self.view addSubview:adBannerView];
        [self updateBannerViewOrientation];
    }
    else
    {
        [self requestAdMobAd];
    }
}

- (void)removeAdMobBannerView
{
    if (adMobAd)
	{
		[adMobAd setDelegate:nil];
		[adMobAd removeFromSuperview];
		[adMobAd release];
		adMobAd = nil;
	}
}

- (void)removeAdBannerView
{
    if (adBannerView)
	{
		[adBannerView setDelegate:nil];
		[adBannerView removeFromSuperview];
		[adBannerView release];
		adBannerView = nil;
	}
}

- (void)removeBannerAd
{
    [self removeAdMobBannerView];
    [self removeAdBannerView];
}

- (void)setAdBannerPosition:(int)pos
{
    if ((pos == kAdBannerPositionTop)||(pos ==kAdBannerPositionBottom))
    {
        adBannerPosition = pos;
    }
    else
    {
        CCLOG(@"Position Not Supported. Setting Position to Top.");
        adBannerPosition = kAdBannerPositionTop;
    }
    
    [self updateBannerViewOrientation];
}

#pragma mark -
#pragma mark Banner Rotation

- (void)rotateBannerViewWithDirector:(UIDeviceOrientation)toDeviceOrientation
{	
	//Get Screen Size
	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    //Banner Position
    int pos = adBannerPosition;
    
    UIView *bannerView = nil;
    
	if (adBannerView)
	{	
		if (UIDeviceOrientationIsLandscape(toDeviceOrientation))
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
		else
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        
        bannerView = (UIView*)adBannerView;
    }
    
    if (adMobAd)
    {
        bannerView = adMobAd;
    }
    
    if (!bannerView) return;
    
    //Restore transform to Identity
    [bannerView setTransform:CGAffineTransformIdentity];
    
    //Get Banner Size
    CGSize bannerSize = bannerView.frame.size;
    
    //Set the transformation for each orientation
    switch (toDeviceOrientation) 
    {
        case UIDeviceOrientationPortrait:
        {
            if (adBannerViewIsVisible)
                [bannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*pos + bannerSize.height*(0.5-pos))];
            else
                [bannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*pos + bannerSize.height*(-0.5+pos))];
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
        {
            [bannerView setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(180))];
            if (adBannerViewIsVisible)
                [bannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*(1-pos) + bannerSize.height*(-0.5+pos))];
            else
                [bannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*(1-pos) + bannerSize.height*(0.5-pos))];
            
        }
            break;
        case UIDeviceOrientationLandscapeLeft:
        {
            [bannerView setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(90))];
            if (adBannerViewIsVisible)
                [bannerView setCenter:CGPointMake(screenSize.width*(1-pos) + bannerSize.height*(-0.5+pos), screenSize.height/2)];
            else
                [bannerView setCenter:CGPointMake(screenSize.width*(1-pos) + bannerSize.height*(0.5-pos), screenSize.height/2)];
        }
            break;
        case UIDeviceOrientationLandscapeRight:
        {
            [bannerView setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(-90))];
            if (adBannerViewIsVisible)
                [bannerView setCenter:CGPointMake(screenSize.width*pos + bannerSize.height*(0.5-pos), screenSize.height/2)];
            else
                [bannerView setCenter:CGPointMake(screenSize.width*pos + bannerSize.height*(-0.5+pos), screenSize.height/2)];
            
        }
            break;
        default: //This case is used to deal with the Unknown device orientation
        {
            if (adBannerViewIsVisible)
                [bannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*pos + bannerSize.height*(0.5-pos))];
            else
                [bannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*pos + bannerSize.height*(-0.5+pos))];
        }
            break;
    }
}

- (void)rotateBannerViewWithUIViewController:(UIInterfaceOrientation)toInterfaceOrientation;
{
    //Get Screen Size
	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    //Banner Position
    int pos = adBannerPosition;
    
    //Set a windowSize based on the orientation, using the Screen Size as reference
    CGSize windowSize;
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) 
        windowSize = CGSizeMake(screenSize.height, screenSize.width);
    else
        windowSize = screenSize;
    
    if (adBannerView) 
    {        
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) 
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
        else 
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        
        CGRect adBannerViewFrame = [adBannerView frame];
        
        if (adBannerViewIsVisible) 
        {
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = pos*(windowSize.height - [self getBannerHeight:toInterfaceOrientation]);
        } 
        else 
        {
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = pos*windowSize.height + (2*pos-1)*[self getBannerHeight:toInterfaceOrientation];
        }
        
        [UIView beginAnimations:@"Animate Banner" context:nil];
        [adBannerView setFrame:adBannerViewFrame];
        [UIView commitAnimations];
    }
    
    if (adMobAd) 
    {    
        CGRect adBannerViewFrame = [adMobAd frame];
        
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) 
        {
            adBannerViewFrame.origin.x = windowSize.width*0.5 - adMobAd.frame.size.width*0.5;
            adBannerViewFrame.origin.y = pos*(windowSize.height - adMobAd.frame.size.height);
        }
        else 
        {
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = pos*(windowSize.height - adMobAd.frame.size.height);
        }
        
        [adMobAd setFrame:adBannerViewFrame];
    }
}

#pragma mark -
#pragma mark ADBannerViewDelegate

- (BOOL)allowActionToRun
{
	return YES;
}

- (void) stopActionsForAd
{	
	//Stop Director
	[[CCDirector sharedDirector] stopAnimation];
	[[CCDirector sharedDirector] pause];
}

- (void) startActionsForAd
{	
    [self updateBannerViewOrientation];
	
	//Resume Director
	[[CCDirector sharedDirector] stopAnimation];
	[[CCDirector sharedDirector] resume];
	[[CCDirector sharedDirector] startAnimation];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	BOOL shouldExecuteAction = [self allowActionToRun];
    if (!willLeave && shouldExecuteAction)
    {
		[self stopActionsForAd];
    }
    return shouldExecuteAction;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{	
	CCLOG(@"iAd Did Load");
	
	[self removeAdMobBannerView];
    
#if ((GAME_AUTOROTATION == kGameAutorotationCCDirector) || (GAME_AUTOROTATION==kGameAutorotationNone))
	if (![self.view.subviews containsObject:adBannerView])
		[self.view addSubview:adBannerView];
#endif
    
    if (!adBannerViewIsVisible) 
    {                
        adBannerViewIsVisible = YES;
        [self updateBannerViewOrientation];
    }
	
	if ((adDelegate != nil) && ([(NSObject *)adDelegate respondsToSelector:@selector(adController: didLoadiAd:)]))
        [adDelegate adController:self didLoadiAd:banner];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{	
	CCLOG(@"iAd Failed To Load With Error: %@", [error localizedDescription]);

#if ((GAME_AUTOROTATION == kGameAutorotationCCDirector) || (GAME_AUTOROTATION==kGameAutorotationNone))
    if ([self.view.subviews containsObject:adBannerView])
		[adBannerView removeFromSuperview];
#endif
    
	if (adBannerViewIsVisible)
    {        
        adBannerViewIsVisible = NO;
        [self updateBannerViewOrientation];
    }
	
	if (!adMobAd)
	{
		CCLOG(@"Loading AdMob Ad...");
		[self requestAdMobAd];
	}
	
    if ((adDelegate != nil) && ([(NSObject *)adDelegate respondsToSelector:@selector(adController: didFailedToRecieveiAd:)]))
        [adDelegate adController:self didFailedToRecieveiAd:banner];
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{	
	[self startActionsForAd];
}

#pragma mark -
#pragma mark AdMobDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    CCLOG(@"AdMob: Did receive ad banner view");
    
    adBannerViewIsVisible = YES;
    [self updateBannerViewOrientation];
	
    if ((adDelegate != nil) && ([(NSObject *)adDelegate respondsToSelector:@selector(adController: didLoadAdMobAd:)]))
        [adDelegate adController:self didLoadAdMobAd:view];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    if (view == adMobAd)
    {
        CCLOG(@"AdMob: Did fail to receive ad banner view with error: %@",[error localizedDescription]);
        adBannerViewIsVisible = NO;
        [self updateBannerViewOrientation];
        
        if ((adDelegate != nil) && ([(NSObject *)adDelegate respondsToSelector:@selector(adController: didFailedToRecieveAdMobAd:)]))
            [adDelegate adController:self didFailedToRecieveAdMobAd:view];
    }
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView
{
    [self stopActionsForAd];
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView
{
    [self startActionsForAd];
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView
{
    [self updateBannerViewOrientation];
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView
{
    
}

#pragma mark -
#pragma mark Interstitial Ads Support

- (void)addInterstitialAd
{
    //Initialize interstitial ad
    interstitialAd = [[GADInterstitial alloc] init];
    interstitialAd.adUnitID = ADMOB_PUBLISHER_ID;
    interstitialAd.delegate = self;
    
    //Initialize ad request
    GADRequest *request = [GADRequest request];
    
    //Testing on for the Simulator, it is ignored in devices
    request.testing = YES;
    
    //Load ad request
    [interstitialAd loadRequest:request];
}

- (void)removeAdMobInterstitialAd
{
    if (interstitialAd)
    {
        [interstitialAd setDelegate:nil];
		[interstitialAd release];
		interstitialAd = nil;
    }
}

- (void)removeInterstitialAd
{
    [self removeAdMobInterstitialAd];
}

#pragma mark -
#pragma mark AdMob IntersticialAdDelegate

// Sent when an interstitial ad request succefully returned an ad.  At the next transition
// point in your application call [ad show] to display the interstitial.
- (void)interstitialDidReceiveAd:(GADInterstitial *)interstitial
{
    if(interstitial == interstitialAd)
    {
        CCLOG(@"AdMob: Did receive interstitial ad");
        [interstitialAd presentFromRootViewController:self];
    }
}

// Sent when an interstitial ad request completed without an interstitial to show.  This is
// common since interstitials are shown sparingly to users.
- (void)interstitial:(GADInterstitial *)interstitial didFailToReceiveAdWithError:(GADRequestError *)error
{
    if(interstitial == interstitialAd)
    {
        CCLOG(@"AdMob: Did fail to recieve interstitial ad with error: %@", [error localizedDescription]);
        [self removeAdMobInterstitialAd];
    }
}

- (void)interstitialWillPresentScreen:(GADInterstitial *)interstitial
{
    [self stopActionsForAd];
}

- (void)interstitialWillDismissScreen:(GADInterstitial *)interstitial
{
    [self startActionsForAd];
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial
{
    [self removeAdMobInterstitialAd];
}

@end

