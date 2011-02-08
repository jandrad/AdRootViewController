//
//  RootViewController.m
//  iAdsTest
//
//  Created by Jose Andrade on 2/1/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

//
// RootViewController + iAd
// If you want to support iAd, use this class as the controller of your iAd
//

#import "cocos2d.h"

#import "AdRootViewController.h"
#import "GameConfig.h"
#import "AdMobView.h"

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

#if GAME_AUTOROTATION==kGameAutorotationCCDirector
-(void) orientationChanged:(NSNotification *)notification
{	
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	
	if (orientation == (UIDeviceOrientation)[[CCDirector sharedDirector] deviceOrientation])
		return;
	
	//if ((orientation == UIDeviceOrientationLandscapeLeft) || (orientation == UIDeviceOrientationLandscapeRight))
	//{
		[[CCDirector sharedDirector] setDeviceOrientation:(ccDeviceOrientation)orientation];
		[self  updateBannerViewOrientation];
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
	
	return YES;//( UIInterfaceOrientationIsLandscape( interfaceOrientation ) );
	
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
    
    //Rotate Ad Banner
    [self rotateBannerViewWithUIViewController:toInterfaceOrientation];
}
#endif // GAME_AUTOROTATION == kGameAutorotationUIViewController


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

#pragma mark -
#pragma mark Helper Methods

- (UIDeviceOrientation)currentOrientation
{
	return [[CCDirector sharedDirector] deviceOrientation];
}

- (void)updateBannerViewOrientation
{
	[self rotateBannerViewWithDirector:[self currentOrientation]];
}

- (int)getBannerHeight:(UIDeviceOrientation)orientation 
{
    if (UIInterfaceOrientationIsLandscape(orientation)) 
        return 32;
    else
        return 50;
}

- (int)getBannerHeight 
{
    return [self getBannerHeight:[UIDevice currentDevice].orientation];
}

#pragma mark -
#pragma mark Ad Support

- (void)addBannerAd
{
    //Initialize the class manually to make it compatible with iOS < 4.0
    Class classAdBannerView = NSClassFromString(@"ADBannerView");
    if (classAdBannerView != nil) 
    {
        adBannerView = [[classAdBannerView alloc] init];
        [adBannerView setDelegate:self];
        [adBannerView setRequiredContentSizeIdentifiers: [NSSet setWithObjects: 
                                                          ADBannerContentSizeIdentifierPortrait, 
                                                          ADBannerContentSizeIdentifierLandscape, nil]];
        
        [self.view addSubview:adBannerView];
        
#if ((GAME_AUTOROTATION==kGameAutorotationNone) || (GAME_AUTOROTATION==kGameAutorotationCCDirector))
        
        [adBannerView setHidden:YES];
        [self updateBannerViewOrientation];
        
#elif GAME_AUTOROTATION == kGameAutorotationUIViewController
        
        adBannerViewIsVisible = NO;
        
        if (UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation))
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
        else
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        
        [adBannerView setFrame:CGRectOffset([adBannerView frame], 0, -[self getBannerHeight])];
        
        [self rotateBannerViewWithUIViewController:[UIDevice currentDevice].orientation];
#endif
    }
    else
    {
        //Request an AdMob Ad
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            adMobAd = [AdMobView requestAdOfSize:ADMOB_SIZE_748x110 withDelegate:self];
        else
            adMobAd = [AdMobView requestAdOfSize:ADMOB_SIZE_320x48 withDelegate:self];
        [adMobAd retain];
    }
}

- (void)removeBannerAd
{
    if (adMobAd)
	{
		[adMobAd setDelegate:nil];
		[adMobAd removeFromSuperview];
		[adMobAd release];
		adMobAd = nil;
	}
    
    if (adBannerView)
	{
		[adBannerView setDelegate:nil];
		[adBannerView removeFromSuperview];
		[adBannerView release];
		adBannerView = nil;
	}
}

- (void)setAdBannerPosition:(char)pos
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
	
	if (adBannerView)
	{	
		if (UIDeviceOrientationIsLandscape(toDeviceOrientation))
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
		else
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
		
        //Restore trandform to identity
        [(UIView*)adBannerView setTransform:CGAffineTransformIdentity];
        
		//Get ADBannerView Frame
		CGSize adBannerViewSize = [adBannerView frame].size;
        
        //Set Frame
		[adBannerView setFrame:CGRectMake(0.f, 0.f, adBannerViewSize.width, adBannerViewSize.height)];
		
		//Set the transformation for each orientation
		switch (toDeviceOrientation) 
		{
			case UIDeviceOrientationPortrait:
			{
				[adBannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*adBannerPosition + adBannerViewSize.height*(0.5-adBannerPosition))];
				if ([adBannerView isHidden])
					[adBannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*adBannerPosition + adBannerViewSize.height*(-0.5+adBannerPosition))];
			}
				break;
			case UIDeviceOrientationPortraitUpsideDown:
			{
				[(UIView*)adBannerView setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(180))];
                [adBannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*(1-adBannerPosition) + adBannerViewSize.height*(-0.5+adBannerPosition))];
				if ([adBannerView isHidden])
                    [adBannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height*(1-adBannerPosition) + adBannerViewSize.height*(0.5-adBannerPosition))];
				
			}
				break;
			case UIDeviceOrientationLandscapeLeft:
			{
				[(UIView*)adBannerView setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(90))];
                [adBannerView setCenter:CGPointMake(screenSize.width*(1-adBannerPosition) + adBannerViewSize.height*(-0.5+adBannerPosition), screenSize.height/2)];
				if ([adBannerView isHidden])
					[adBannerView setCenter:CGPointMake(screenSize.width*(1-adBannerPosition) + adBannerViewSize.height*(0.5-adBannerPosition), screenSize.height/2)];
			}
				break;
			case UIDeviceOrientationLandscapeRight:
			{
				[(UIView*)adBannerView setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(-90))];
                [adBannerView setCenter:CGPointMake(screenSize.width*adBannerPosition + adBannerViewSize.height*(0.5-adBannerPosition), screenSize.height/2)];
				if ([adBannerView isHidden])
					[adBannerView setCenter:CGPointMake(screenSize.width*adBannerPosition + adBannerViewSize.height*(-0.5+adBannerPosition), screenSize.height/2)];
				
			}
				break;
			default:
				break;
		}
	}
	
	if (adMobAd)
	{
		[adMobAd setTransform:CGAffineTransformIdentity];
		
		CGSize adMobAdSize = adMobAd.frame.size;
		
		//Set the transformation for each orientation
		switch (toDeviceOrientation) 
		{
			case UIDeviceOrientationPortrait:
			{
                [adMobAd setCenter:CGPointMake(screenSize.width/2, screenSize.height*adBannerPosition + adMobAdSize.height*(0.5-adBannerPosition))];
			}
				break;
			case UIDeviceOrientationPortraitUpsideDown:
			{
				[adMobAd setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(180))];
                [adMobAd setCenter:CGPointMake(screenSize.width/2, screenSize.height*(1-adBannerPosition) + adMobAdSize.height*(-0.5+adBannerPosition))];
			}
				break;
			case UIDeviceOrientationLandscapeLeft:
			{
				[adMobAd setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(90))];
                [adMobAd setCenter:CGPointMake(screenSize.width*(1-adBannerPosition) + adMobAdSize.height*(-0.5+adBannerPosition), screenSize.height/2)];
			}
				break;
			case UIDeviceOrientationLandscapeRight:
			{
				[adMobAd setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(-90))];
                [adMobAd setCenter:CGPointMake(screenSize.width*adBannerPosition + adMobAdSize.height*(+0.5-adBannerPosition), screenSize.height/2)];
			}
				break;
			default:
				break;
		}
	}
}

- (void)rotateBannerViewWithUIViewController:(UIInterfaceOrientation)toInterfaceOrientation;
{
    if (adBannerView) 
    {        
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) 
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
        else 
            [adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        
        if (adBannerViewIsVisible) 
        {
            CGRect adBannerViewFrame = [adBannerView frame];
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = adBannerPosition*(self.view.frame.size.height - [self getBannerHeight:toInterfaceOrientation]);
            [adBannerView setFrame:adBannerViewFrame];
        } 
        else 
        {
            CGRect adBannerViewFrame = [adBannerView frame];
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = adBannerPosition*self.view.frame.size.height + (2*adBannerPosition-1)*[self getBannerHeight:toInterfaceOrientation];
            [adBannerView setFrame:adBannerViewFrame];
        }
        
    }
    
    if (adMobAd) 
    {    
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) 
        {
            CGRect adBannerViewFrame = [adMobAd frame];
            adBannerViewFrame.origin.x = self.view.frame.size.width*0.5 - adMobAd.frame.size.width*0.5;
            adBannerViewFrame.origin.y = adBannerPosition*(self.view.frame.size.height - adMobAd.frame.size.height);
            [adMobAd setFrame:adBannerViewFrame];
        }
        else 
        {
            CGRect adBannerViewFrame = [adMobAd frame];
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = adBannerPosition*(self.view.frame.size.height - adMobAd.frame.size.height);
            [adMobAd setFrame:adBannerViewFrame];
        }
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
#if ((GAME_AUTOROTATION == kGameAutorotationCCDirector) || (GAME_AUTOROTATION==kGameAutorotationNone))
	[self updateBannerViewOrientation];
	[[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation)[self currentOrientation]];
#endif
	
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
	
	if (adMobAd)
	{
		[adMobAd setDelegate:nil];
		[adMobAd removeFromSuperview];
		[adMobAd release];
		adMobAd = nil;
	}
    
#if ((GAME_AUTOROTATION == kGameAutorotationCCDirector) || (GAME_AUTOROTATION==kGameAutorotationNone))
	if (![self.view.subviews containsObject:adBannerView])
		[self.view addSubview:adBannerView];
	
	[adBannerView setHidden:NO];
	[self updateBannerViewOrientation];
#elif GAME_AUTOROTATION==kGameAutorotationUIViewController
    if (!adBannerViewIsVisible) 
    {                
        adBannerViewIsVisible = YES;
        [self rotateBannerViewWithUIViewController:[UIDevice currentDevice].orientation];
    }
#endif
	
	if ((adDelegate != nil) && ([(NSObject *)adDelegate respondsToSelector:@selector(adController: didLoadiAd:)]))
        [adDelegate adController:self didLoadiAd:banner];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{	
	CCLOG(@"iAd Failed To Load With Error: %@", [error localizedDescription]);

#if ((GAME_AUTOROTATION == kGameAutorotationCCDirector) || (GAME_AUTOROTATION==kGameAutorotationNone))
	[adBannerView setHidden:YES];
	
	if ([self.view.subviews containsObject:adBannerView])
		[adBannerView removeFromSuperview];
#elif GAME_AUTOROTATION==kGameAutorotationUIViewController
    if (adBannerViewIsVisible)
    {        
        adBannerViewIsVisible = NO;
        [self rotateBannerViewWithUIViewController:[UIDevice currentDevice].orientation];
    }
#endif
	
	if (!adMobAd)
	{
		CCLOG(@"Loading AdMob Ad...");
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			adMobAd = [AdMobView requestAdOfSize:ADMOB_SIZE_748x110 withDelegate:self];
		else
			adMobAd = [AdMobView requestAdOfSize:ADMOB_SIZE_320x48 withDelegate:self];
		[adMobAd retain];
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

- (NSString *)publisherIdForAd:(AdMobView *)adView 
{
	return @"a14a8d567c90c4c"; // this should be prefilled; if not, get it from www.admob.com
}

- (UIViewController *)currentViewControllerForAd:(AdMobView *)adView {
	return self;
}

- (UIColor *)adBackgroundColorForAd:(AdMobView *)adView 
{
	return [UIColor colorWithRed:0 green:0 blue:0 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (UIColor *)primaryTextColorForAd:(AdMobView *)adView 
{
	return [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (UIColor *)secondaryTextColorForAd:(AdMobView *)adView 
{
	return [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (NSArray *)testDevices 
{
	return [NSArray arrayWithObjects:
			ADMOB_SIMULATOR_ID,								//iPhone Simulator
			nil];
}

- (void)didReceiveAd:(AdMobView *)adView 
{
	CCLOG(@"AdMob: Did receive ad");
	
	[self updateBannerViewOrientation];
	[self.view addSubview:adMobAd];
	[self.view sendSubviewToBack:adMobAd];
	
    if ((adDelegate != nil) && ([(NSObject *)adDelegate respondsToSelector:@selector(adController: didLoadAdMobAd:)]))
        [adDelegate adController:self didLoadAdMobAd:adView];
}

// Sent when an ad request failed to load an ad
- (void)didFailToReceiveAd:(AdMobView *)adView 
{
	CCLOG(@"AdMob: Did fail to receive ad");
	[adMobAd removeFromSuperview];
	[adMobAd release];
	adMobAd = nil;
	
    if ((adDelegate != nil) && ([(NSObject *)adDelegate respondsToSelector:@selector(adController: didFailedToRecieveAdMobAd:)]))
        [adDelegate adController:self didFailedToRecieveAdMobAd:adView];
}

- (void) stopActionsForAdMobAd
{	
	[[CCDirector sharedDirector] stopAnimation];
	[[CCDirector sharedDirector] pause];
}

- (void) startActionsForAdMobAd
{	
	[[CCDirector sharedDirector] stopAnimation];
	[[CCDirector sharedDirector] resume];
	[[CCDirector sharedDirector] startAnimation];
}

- (void)didPresentFullScreenModalFromAd:(AdMobView *)adView
{
	[self stopActionsForAdMobAd];
}

- (void)willDismissFullScreenModalFromAd:(AdMobView *)adView
{
	[self startActionsForAdMobAd];
}

- (void)didDismissFullScreenModalFromAd:(AdMobView *)adView
{
#if ((GAME_AUTOROTATION == kGameAutorotationCCDirector) || (GAME_AUTOROTATION==kGameAutorotationNone))
	[self updateBannerViewOrientation];
	[[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation)[self currentOrientation]];
#endif
}

#pragma mark -
#pragma mark Memory Management

- (void) dealloc
{	
	[self removeBannerAd];
    [super dealloc];
}

@end

