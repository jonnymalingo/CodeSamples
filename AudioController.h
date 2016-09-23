//
//  AudioController.h
//  Superheroes
//
//  Created by Jonathan Gerber on 6/27/13.
//  Copyright (c) 2013 Jonathan Gerber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioController : NSObject <AVAudioPlayerDelegate>

@property (nonatomic) AVAudioPlayer *audioPlayer;
@property (nonatomic) AVAudioPlayer *effectsPlayer;
@property (nonatomic) NSArray *playlist;
@property (nonatomic) NSInteger currTrack;
- (void)startPlayingBackgroundMusic;

- (void)stopPlayingBackgroundMusic;

- (void)stopPlayingAllMusic;

- (void)playSoundEffect:(NSString *)soundEffect;

- (void)playBackgroundMusicStartingAtSong:(NSString *)song;
@end
