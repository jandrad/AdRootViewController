//
//  HelloWorldScene.h
//  iAdsTest
//
//  Created by Jose Andrade on 2/1/11.
//  Copyright Jose Andrade 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorld Layer
@interface HelloWorld : CCLayerColor
{
}

// returns a Scene that contains the HelloWorld as the only child
+(id) scene;

-(void)updatePositions;

@end
