//
//  MainMenuScene.m
//  Twids
//
//  Created by Jonathan Gerber on 9/1/13.
//  Copyright (c) 2013 Malingo Studios. All rights reserved.
//

#import "MainMenuScene.h"
#import "Level.h"
#import "PurchaseController.h"
#import "AppDelegate.h"
#import "Stage.h"
#import "MyScene.h"
#import <Social/Social.h>
#import "ViewController.h"
#import "LevelMenuScene.h"

@interface MainMenuScene ()

@property (nonatomic) SKSpriteNode *levelMenu;
@property (nonatomic) NSMutableArray *levelButtons;
@property (nonatomic) SKSpriteNode *animationLayer;
@property (nonatomic) Level *currentLevel;
@property (nonatomic) SKScene *scene;
@property (nonatomic) SKLabelNode *title;
@property (nonatomic) PurchaseController *purchaseController;
@property (nonatomic) SKSpriteNode *keyButton;
@property (nonatomic) SKSpriteNode *facebookButton;
@property (nonatomic) SKSpriteNode *twitterButton;
@property (nonatomic) UIAlertView *purchaseAlert;

@end

@implementation MainMenuScene

- (id) initWithSize:(CGSize)size
{
    if ((self = [super initWithSize:size]))
	{
        self.backgroundColor = [SKColor whiteColor];
        
        [self loadSubviews];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expansionPurchased:) name:@"expansionPurchased" object:nil];
	}
    
	return self;
}

- (void)expansionPurchased:(NSNotification *)notif
{
    [self levelButtonTapped:[self.levelButtons objectAtIndex:(self.currentLevel.guid.intValue-1)]];
}

- (void) loadSubviews
{

    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    if (![defs objectForKey:@"shownIntro"]) {
        [self performSelector:@selector(openPractice) withObject:nil afterDelay:0.05f];
        [defs setObject:[NSNumber numberWithBool:YES] forKey:@"shownIntro"];
        [defs synchronize];
    }
    
    [self performSelector:@selector(loadViewsAfterDelay) withObject:nil afterDelay:.1f];
}

- (void)loadViewsAfterDelay
{
    CGSize windowSize = [[AppDelegate appDelegate] window].frame.size;
    
    
    SKSpriteNode *titleSidebar = [SKSpriteNode spriteNodeWithImageNamed:@"title-sidebar.png"];
    int x = 60;
    int y = 0;
    int titleY = 0;
    if (windowSize.height == 480) {
        y = -60;
        titleY = -60;
        [titleSidebar setScale:0.6f];
    } else {
        [titleSidebar setScale:0.5f];
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [titleSidebar setScale:1.0f];
        titleY = 250;
        y = 50;
        x = 110;
    }
    [titleSidebar setZPosition:2];
    [titleSidebar setAnchorPoint:CGPointMake(0, 0)];
    [titleSidebar setPosition:CGPointMake(0, 200+titleY)];
    
    [self addChild:titleSidebar];
    
    self.levelButtons = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (int i = 1; i <= 9; i++) {
        NSString *img = [NSString stringWithFormat:@"%d-btn.png", i];
        SKSpriteNode *btn = [SKSpriteNode spriteNodeWithImageNamed:img];
        
        int offset;
        if (windowSize.height <= 480) {
            offset = 1;
        } else {
            offset = 10;
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [btn setScale:1.1f];
        } else {
            [btn setScale:0.55f];
        }
        [btn setAnchorPoint:CGPointMake(0.5, 0.5)];

        NSMutableDictionary *userData = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"tag"];
        [btn setUserData:userData];
        [btn setName:@"level"];
        [btn setPosition:CGPointMake(x, 210+y)];
        
        [self.levelButtons addObject:btn];
        [self addChild:btn];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            x += 70;
        } else {
            x += 30;
        }
        
    }
    
    int offset;
    
    if (windowSize.height <= 480) {
        offset = 50;
        y=-50;
        titleY = 20;
        x = -15;
    } else {
        offset = 30;
        x = 0;
    }
    self.animationLayer = [[SKSpriteNode alloc] init];
    [self.animationLayer setAnchorPoint:CGPointMake(0, 0)];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.animationLayer setSize:CGSizeMake((windowSize.height/2)+100, (windowSize.width/2)+60)];
        [self.animationLayer setPosition:CGPointMake(80+x, 245+y)];
    } else {
        [self.animationLayer setSize:CGSizeMake((windowSize.height/2)-15, (windowSize.width/2)-25)];
        [self.animationLayer setPosition:CGPointMake(40+x, 225+y)];
    }
    [self addChild:self.animationLayer];
    self.currentLevel = [Level levelForNumber:1];
    
    self.title = [SKLabelNode labelNodeWithFontNamed:@"QuicksandBook-Regular"];
    [self.title setText:@""];
    [self.title setFontColor:[SKColor colorWithRed:0 green:(125.0f/255.0f) blue:(175.0f/255.0f) alpha:1.0f]];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.title setPosition:CGPointMake((windowSize.height/2)+offset-160, 450+y+titleY)];
        [self.title setFontSize:56];
        [self.title setScale:0.5f];
    } else {
        [self.title setPosition:CGPointMake((windowSize.height/4)+offset, 350+y+titleY)];
        [self.title setFontSize:24];
        [self.title setScale:0.5f];
    }
    
    [self addChild:self.title];
    
    [self levelButtonTapped:nil];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (self.startLevel) {
            [(SKSpriteNode *)[self.levelButtons objectAtIndex:self.startLevel-1] setScale:1.4f];
        } else {
            [(SKSpriteNode *)[self.levelButtons objectAtIndex:0] setScale:1.4f];
        }
    } else {
        if (self.startLevel) {
            [(SKSpriteNode *)[self.levelButtons objectAtIndex:self.startLevel-1] setScale:.7f];
        } else {
            [(SKSpriteNode *)[self.levelButtons objectAtIndex:0] setScale:.7];
        }
    }
    
}

- (void) openPractice
{
    MyScene * scene = [[MyScene alloc] initWithSize:self.size stage:nil];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    // Present the scene.
    [[[AppDelegate appDelegate] navController] presentScene:scene transition:nil];
}


- (void)levelButtonTapped:(SKSpriteNode *)sender
{
    int levelNum = [self.currentLevel.guid intValue];
    if (self.startLevel) {
        levelNum = self.startLevel;
    }
    if (sender) {
        levelNum = [[[sender userData] objectForKey:@"tag"] intValue];
        self.startLevel = levelNum;
    }
    
    Level *level = [Level levelForNumber:levelNum];
    if (level) {
        [self.title setText:level.title];
        if (sender) {
            for (SKSpriteNode *item in self.levelButtons) {
                
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    [item setScale:1.1f];
                } else {
                    [item setScale:.55f];
                }
            }
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [sender runAction:[SKAction sequence:@[[SKAction scaleTo:0.8f duration:0.1f], [SKAction scaleTo:1.6f duration:0.1f],  [SKAction scaleTo:1.4 duration:0.1f]]]];
            } else {
                [sender runAction:[SKAction sequence:@[[SKAction scaleTo:0.4f duration:0.1f], [SKAction scaleTo:.8f duration:0.1f],  [SKAction scaleTo:.7 duration:0.1f]]]];
            }
            
        }
        self.currentLevel = level;
        [self.animationLayer removeAllChildren];
        NSArray *stages = [Stage stagesForLevel:level.guid.integerValue];
        [self fadeStage:[stages objectAtIndex:0] stages:stages];
        if (sender) {
            SKAction *sound =[SKAction playSoundFileNamed:@"Menu_Nav_Pack_8_03_Setting_Toggle.mp3" waitForCompletion:NO];
            [self runAction:sound];
        }
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        if (levelNum == 3 && ![[defs objectForKey:@"shared"] boolValue]) {
            SKLabelNode *restriction = [SKLabelNode labelNodeWithFontNamed:@"QuicksandBook-Regular"];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [restriction setFontSize:40];
                [restriction setScale:0.5f];
            } else {
                [restriction setFontSize:20];
                [restriction setScale:0.5f];
            }
            
            [restriction setText:@"Share to unlock"];
            [restriction setZPosition:4];
            if ([[AppDelegate appDelegate] window].frame.size.height == 480) {
                [restriction setPosition:CGPointMake(230,145)];
            } else {
                [restriction setPosition:CGPointMake(230,125)];
            }
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                 [restriction setPosition:CGPointMake(580,455)];
            }
            [restriction setFontColor:[SKColor colorWithRed:0 green:(125.0f/255.0f) blue:(175.0f/255.0f) alpha:1.0f]];
            [self.animationLayer addChild:restriction];
            
            self.facebookButton = [SKSpriteNode spriteNodeWithImageNamed:@"facebookBtn.png"];
            self.twitterButton = [SKSpriteNode spriteNodeWithImageNamed:@"twitterBtn.png"];
            if ([[AppDelegate appDelegate] window].frame.size.height == 480) {
                [self.facebookButton setPosition:CGPointMake(215, 135)];
                [self.twitterButton setPosition:CGPointMake(245, 135)];
            } else {
                [self.facebookButton setPosition:CGPointMake(215, 115)];
                [self.twitterButton setPosition:CGPointMake(245, 115)];
            }
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [self.facebookButton setPosition:CGPointMake(550,425)];
                [self.twitterButton setPosition:CGPointMake(610,425)];
                [self.facebookButton setScale:0.6f];
                [self.twitterButton setScale:0.6f];
            } else {
                [self.facebookButton setScale:0.3f];
                [self.twitterButton setScale:0.3f];
            }
            
            [self.facebookButton setZPosition:2];
            [self.twitterButton setZPosition:2];
            [self.animationLayer addChild:self.facebookButton];
            [self.animationLayer addChild:self.twitterButton];
        } else if (levelNum >= 4 && levelNum <= 9 && ![[defs objectForKey:@"expansion"] boolValue]) {
            SKLabelNode *restriction = [SKLabelNode labelNodeWithFontNamed:@"QuicksandBook-Regular"];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [restriction setFontSize:40];
                [restriction setScale:0.5f];
            } else {
                [restriction setFontSize:20];
                [restriction setScale:0.5f];
            }
            [restriction setText:@"Expansion only"];
            self.keyButton = [SKSpriteNode spriteNodeWithImageNamed:@"keyBtn.png"];
            if ([[AppDelegate appDelegate] window].frame.size.height == 480) {
                [restriction setPosition:CGPointMake(230,145)];
                [self.keyButton setPosition:CGPointMake(230, 130)];
            } else {
                [restriction setPosition:CGPointMake(230,125)];
                [self.keyButton setPosition:CGPointMake(230, 110)];
            }
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                [restriction setPosition:CGPointMake(550,455)];
                [self.keyButton setPosition:CGPointMake(550,425)];
                [self.keyButton setScale:1.2f];
            } else {
                [self.keyButton setScale:0.6f];
            }
            [restriction setFontColor:[SKColor colorWithRed:0 green:(125.0f/255.0f) blue:(175.0f/255.0f) alpha:1.0f]];
            [restriction setZPosition:3];
            [self.animationLayer addChild:restriction];
            
            
            [self.keyButton setZPosition:3];
            [self.animationLayer addChild:self.keyButton];
        }
        
    }
}

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)fadeStage:(Stage *)stage stages:(NSArray *)stages
{
    NSUInteger currentInt = [stages indexOfObject:stage];
    Stage *nextStage;
    if ([stages count] > currentInt+1) {
        nextStage = [stages objectAtIndex:(currentInt+1)];
    }
    
    NSString *imgName = [NSString stringWithFormat:@"%d-%d.png", [stage.levelNum intValue], [stage.displayNum intValue]];
    SKSpriteNode *img = [SKSpriteNode spriteNodeWithImageNamed:imgName];//
    [img setAlpha:0];
    [img setAnchorPoint:CGPointMake(0, 0)];
    [img setPosition:CGPointMake(30, 0)];
    if ([[AppDelegate appDelegate] window].frame.size.height == 480) {
        [img setScale:0.45];
    } else {
        [img setScale:0.4];
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [img setScale:1.0f];
        [img setPosition:CGPointMake(50, 70)];
    }
    
    [self.animationLayer addChild:img];
    
    NSMutableArray *actions = [NSMutableArray array];
    
    SKAction *fadeIn = [SKAction fadeInWithDuration:.75];
    [actions addObject:fadeIn];
    
    if (nextStage) {
        SKAction *block = [SKAction runBlock:^{
            [self fadeStage:nextStage stages:stages];
        }];
        SKAction *delay = [SKAction waitForDuration:0.75f];
        SKAction *block2 = [SKAction runBlock:^{
            if (img) {
                [img removeFromParent];
            }
        }];

        [actions addObject:block];
        [actions addObject:delay];
        [actions addObject:block2];
    } else {
        SKAction *delay = [SKAction waitForDuration:0.8f];
        SKAction *block1 = [SKAction runBlock:^{
            [self levelButtonTapped:nil];
        }];

        [actions addObject:delay];
        [actions addObject: block1];
    }
    [img runAction:[SKAction sequence:actions]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    CGPoint locationInAnimation = [touch locationInNode:self.animationLayer];
    for (SKSpriteNode *node in self.levelButtons) {
        if ([node containsPoint:location]) {
            [self levelButtonTapped:node];
            return;
        }
    }
    if ([self.keyButton containsPoint:locationInAnimation]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [self.keyButton runAction:[SKAction sequence:@[[SKAction scaleTo:1.0f duration:0.1f], [SKAction scaleTo:1.5f duration:0.1f],  [SKAction scaleTo:1.2f duration:0.1f]]]];
        } else {
            [self.keyButton runAction:[SKAction sequence:@[[SKAction scaleTo:0.5f duration:0.1f], [SKAction scaleTo:.75f duration:0.1f],  [SKAction scaleTo:.6 duration:0.1f]]]];
        }
        
        if (!self.purchaseController) {
            self.purchaseController = [[PurchaseController alloc] init];
        }
        if ([self.purchaseController purchasingAvailable]) {
            [self.purchaseController setSelectedProduct:@"com.malingo.twids.expansion"];
            [self.purchaseController requestAppleProductsFromSet:[self.purchaseController productIDs]];
        }
        return;
    }
    if ([self.facebookButton containsPoint:locationInAnimation]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [self.facebookButton runAction:[SKAction sequence:@[[SKAction scaleTo:0.4f duration:0.1f], [SKAction scaleTo:.8f duration:0.1f],  [SKAction scaleTo:.6f duration:0.1f]]]];
        } else {
            [self.facebookButton runAction:[SKAction sequence:@[[SKAction scaleTo:0.2f duration:0.1f], [SKAction scaleTo:.4f duration:0.1f],  [SKAction scaleTo:.3 duration:0.1f]]]];
        }
        
            if(NSClassFromString(@"SLComposeViewController") != nil) {
                if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) //check if Facebook Account is linked
                {
                    SLComposeViewController * mySLComposerSheet = [[SLComposeViewController alloc] init]; //initiate the Social Controller
                    mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook]; //Tell him with what social plattform to use it, e.g. facebook or twitter
                    NSString *msg = nil;
                    
                    msg = @"Stretch your brain with Twids for iOS!";
                    
                    [mySLComposerSheet setInitialText:[NSString stringWithFormat:@"%@",msg]]; //the message you want to post
                    [mySLComposerSheet addURL:[NSURL URLWithString:@"http://bit.ly/14JFbbZ"]];
                    [mySLComposerSheet addImage:[UIImage imageNamed:@"appicon@2x.png"]]; //an image you could post
                    [[[AppDelegate appDelegate] navController] presentViewController:mySLComposerSheet animated:YES completion:nil];
                    
                    [mySLComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
                        switch (result) {
                            case SLComposeViewControllerResultCancelled:
                                break;
                            case SLComposeViewControllerResultDone:
                            {
                                NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
                                [defs setObject:[NSNumber numberWithBool:YES] forKey:@"shared"];
                                [defs synchronize];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self levelButtonTapped:[self.levelButtons objectAtIndex:2]];
                                });
                            }
                                break;
                            default:
                                break;
                        }
                    }];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please log in to Facebook to post" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            }

        return;
    }
    if ([self.twitterButton containsPoint:locationInAnimation]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [self.twitterButton runAction:[SKAction sequence:@[[SKAction scaleTo:0.4f duration:0.1f], [SKAction scaleTo:.8f duration:0.1f],  [SKAction scaleTo:.6f duration:0.1f]]]];
        } else {
            [self.twitterButton runAction:[SKAction sequence:@[[SKAction scaleTo:0.2f duration:0.1f], [SKAction scaleTo:.4f duration:0.1f],  [SKAction scaleTo:.3 duration:0.1f]]]];
        }
        
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) //check if Facebook Account is linked
        {
            SLComposeViewController *mySLComposerSheet = [[SLComposeViewController alloc] init]; //initiate the Social Controller
            mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter]; //Tell him with what social plattform to use it, e.g. facebook or twitter
            NSString *msg = nil;
            
            msg = @"Stretch your brain with Twids for iOS!";
            [mySLComposerSheet setInitialText:[NSString stringWithFormat:@"%@",msg]]; //the message you want to post
            [mySLComposerSheet addURL:[NSURL URLWithString:@"http://bit.ly/14JFbbZ"]];
            [mySLComposerSheet addImage:[UIImage imageNamed:@"appicon@2x.png"]]; //an image you could post
        
            [[[AppDelegate appDelegate] navController] presentViewController:mySLComposerSheet animated:YES completion:nil];
            [mySLComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
                switch (result) {
                    case SLComposeViewControllerResultCancelled:
                        break;
                    case SLComposeViewControllerResultDone:
                    {
                        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
                        [defs setObject:[NSNumber numberWithBool:YES] forKey:@"shared"];
                        [defs synchronize];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self levelButtonTapped:[self.levelButtons objectAtIndex:2]];
                        });
                        
                    }
                        break;
                    default:
                        break;
                }
            }];
        } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please log in to Twitter to post" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
        }
        return;
    }
    if ([self.animationLayer containsPoint:location]) {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        int level = self.currentLevel.guid.intValue;
        if ((level == 3 && ![[defs objectForKey:@"shared"] boolValue]) || (level >= 4 && level <= 9 && ![[defs objectForKey:@"expansion"] boolValue])) {
            if (level == 3) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Share Required" message:@"Level 3 can be unlocked by sharing on Facebook or Twitter" delegate:self cancelButtonTitle:@"Close" otherButtonTitles: nil];
                [alert show];
            } else {
                self.purchaseAlert = [[UIAlertView alloc] initWithTitle:@"Expansion Required" message:@"Levels 4 - 9 can be unlocked for $.99" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Unlock", @"Restore", nil];
                [self.purchaseAlert show];
            }
            return;
        }
        SKAction *sound =[SKAction playSoundFileNamed:@"Menu_Nav_Pack_8_04_Accept_Changes.mp3" waitForCompletion:NO];
        [self runAction:sound];
        SKTransition *transition = [SKTransition moveInWithDirection:SKTransitionDirectionDown duration:0.4f];
        LevelMenuScene *scene = [[LevelMenuScene alloc] initWithSize:self.size level:self.currentLevel];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        [[[AppDelegate appDelegate] navController] presentScene:scene transition:transition];
        return;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && alertView == self.purchaseAlert) {
        if (!self.purchaseController) {
            self.purchaseController = [[PurchaseController alloc] init];
        }
        if ([self.purchaseController purchasingAvailable]) {
            [self.purchaseController setSelectedProduct:@"com.malingo.twids.expansion"];
            [self.purchaseController requestAppleProductsFromSet:[self.purchaseController productIDs]];
        }
    } else if (buttonIndex == 2 && alertView == self.purchaseAlert) {
        if (!self.purchaseController) {
            self.purchaseController = [[PurchaseController alloc] init];
        }
        if ([self.purchaseController purchasingAvailable]) {
            [self.purchaseController restoreCompletedTransactions];
        }
    }
}

@end
