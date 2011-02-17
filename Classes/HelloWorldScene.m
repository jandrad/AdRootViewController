//
//  HelloWorldLayer.m
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright ___ORGANIZATIONNAME___ ___YEAR___. All rights reserved.
//

// Import the interfaces
#import "HelloWorldScene.h"

#import "iAdsTestAppDelegate.h"
#import "AdRootViewController.h"

enum tags 
{
    kTitleLabelTag = 0,
    kMenuTag
};

// HelloWorld implementation
@implementation HelloWorld

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorld *layer = [HelloWorld node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (AdRootViewController*)appController
{
    return [(iAdsTestAppDelegate*)[[UIApplication sharedApplication] delegate] viewController];
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) 
    {
        CCLabelTTF *label = [CCLabelTTF labelWithString:@"Hello Ads" fontName:@"Marker Felt" fontSize:32];
        label.tag = kTitleLabelTag;
        [self addChild: label];
        
        
        CCMenuItemFont *requestAd = [CCMenuItemFont itemFromString:@"Request Banner Ad"];
        CCMenuItemFont *removeAd = [CCMenuItemFont itemFromString:@"Remove Banner Ad"];
        
        CCMenuItemFont *positionTop = [CCMenuItemFont itemFromString:@"Banner Position Top"];
        CCMenuItemFont *positionBottom = [CCMenuItemFont itemFromString:@"Banner Position Bottom"];
        
        CCMenuItemToggle *bannerAd = [CCMenuItemToggle itemWithTarget:self selector:@selector(requestBannerAd:) items:requestAd, removeAd, nil]; 
        CCMenuItemToggle *bannerPosition = [CCMenuItemToggle itemWithTarget:self selector:@selector(setBannerPosition:) items:positionTop, positionBottom, nil]; 
        CCMenuItemFont *interstitialAd = [CCMenuItemFont itemFromString:@"Request Interstitial Ad" target:self selector:@selector(requestInterstitialAd:)];
        
        CCMenu* menu = [CCMenu menuWithItems:bannerPosition, bannerAd,interstitialAd, nil];
        menu.tag = kMenuTag;
        [menu alignItemsVertically];
        [self addChild:menu];
        
        [self updatePositions];
	}
	return self;
}

-(void)updatePositions
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    [[self getChildByTag:kTitleLabelTag] setPosition:ccp( size.width*0.5 , size.height*0.85 )];
    [[self getChildByTag:kMenuTag] setPosition:ccp(size.width*0.5, size.height*0.45)];
}

- (void)setBannerPosition:(CCMenuItemToggle*)toggle
{
    switch (toggle.selectedIndex) 
    {
        case 0:
            [[self appController] setAdBannerPosition:kAdBannerPositionTop];
            break;
        case 1:
            [[self appController] setAdBannerPosition:kAdBannerPositionBottom];
            break;
        default:
            break;
    }
}

- (void)requestBannerAd:(CCMenuItemToggle*)toggle
{
    switch (toggle.selectedIndex) 
    {
        case 0:
            [[self appController] removeBannerAd];
            break;
        case 1:
            [[self appController] addBannerAd];
            break;
        default:
            break;
    }
}

- (void)requestInterstitialAd:(id)sender
{
    [[self appController] addInterstitialAd];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
