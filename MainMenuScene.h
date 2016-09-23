//
//  MainMenuScene.h
//  Twids
//
//  Created by Jonathan Gerber on 9/1/13.
//  Copyright (c) 2013 Malingo Studios. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class ViewController;

@interface MainMenuScene : SKScene <UIAlertViewDelegate>

@property (nonatomic) ViewController *viewController;
@property (nonatomic) int startLevel;
@end
