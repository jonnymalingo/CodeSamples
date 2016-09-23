//
//  AudioController.m
//  Superheroes
//
//  Created by Jonathan Gerber on 6/27/13.
//  Copyright (c) 2013 Jonathan Gerber. All rights reserved.
//

#import "AudioController.h"

@implementation AudioController

- (id) init
{
    self = [super init];
    if (self) {
        self.playlist = [NSArray arrayWithObjects:@"revenge", @"Heroes_Of_The_Past", @"Cinema_Orch_Epic_90", @"Heroes", nil];
        self.currTrack = 0;
    }
    return self;
}

- (void)startPlayingBackgroundMusic
{
    [self playBackgroundMusicStartingAtSong:[self.playlist objectAtIndex:self.currTrack]];
}

- (void)playBackgroundMusicStartingAtSong:(NSString *)song
{
    NSString *bundleRootPath = [[NSBundle mainBundle] pathForResource:song ofType:@"mp3"];
    NSURL* file = [NSURL URLWithString:bundleRootPath];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:nil];
    [self.audioPlayer setNumberOfLoops:0];
    self.audioPlayer.delegate = self;
    
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

- (void)stopPlayingBackgroundMusic
{
    [self.audioPlayer stop];
}

- (void)stopPlayingAllMusic {
    [self.audioPlayer stop];
    [self.effectsPlayer stop];
}

- (void)playSoundEffect:(NSString *)fileName
{
    NSString *bundleRootPath = [[NSBundle mainBundle] pathForResource:[fileName stringByDeletingPathExtension] ofType:@"mp3"];
    
    NSURL* file = [NSURL URLWithString:bundleRootPath];
    NSError *e;
    self.effectsPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:&e];
    
    [self.effectsPlayer setNumberOfLoops:0];
    self.effectsPlayer.delegate = self;
    [self.effectsPlayer setVolume:1.0f];
    [self.effectsPlayer prepareToPlay];
    [self.effectsPlayer play];
}

- (void)playSoundEffect:(NSString *)fileName pitch:(float )pitch
{
    NSString *bundleRootPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mp3"];
    NSURL* file = [NSURL URLWithString:bundleRootPath];
    
    self.effectsPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:nil];
    [self.effectsPlayer setNumberOfLoops:0];
    self.effectsPlayer.delegate = self;
    [self.effectsPlayer setVolume:0.4f];
    
    [self.effectsPlayer prepareToPlay];
    [self.effectsPlayer play];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (player == self.audioPlayer) {
        int nextTrack = self.currTrack + 1;
        if (nextTrack >= [self.playlist count]) {
            self.currTrack = 0;
        } else {
            self.currTrack++;
        }
        [self playBackgroundMusicStartingAtSong:[self.playlist objectAtIndex:self.currTrack]];
    }
    
}

- (void)setCurrTrack:(NSInteger)currTrack
{
    _currTrack = currTrack;
}

@end
