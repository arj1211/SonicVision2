//
//  AudioEngine.m
//  BreakfastFinder
//
//  Created by Dhruv Mathur on 2023-03-05.
//  Copyright © 2023 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "AudioManager.h"

@interface AudioEngine ()
    @property (nonatomic, strong) AVAudioEngine *audioEngine;
    @property (nonatomic, strong) AVAudioEnvironmentNode *audioEnvironmentNode;
    @property (nonatomic, strong) AVAudioPlayerNode *audioPlayerNode;
    @property (nonatomic, strong) NSMutableArray <AVAudioPlayerNode*> *audioPlayerNodeArray;

    @property (nonatomic, strong) AVAudioFile *hornSound;
    @property (nonatomic, strong) AVAudioFile *personSound;
    @property (nonatomic, strong) AVAudioFile *chairSound;
    @property (nonatomic, strong) AVAudioFile *bottleSound;
    @property (nonatomic, strong) AVAudioFile *laptopSound;

@end

@implementation AudioEngine

- (void)addNodeAndPlayWith:(Float32)x y:(Float32)y z:(Float32)z distance:(Float32)distance type:(NSNumber*)type {
    AVAudioPlayerNode* newNode = [[AVAudioPlayerNode alloc] init];
    [self.audioEngine attachNode:newNode];
    
    AVAudioFormat *inputFormat = [self.audioEnvironmentNode inputFormatForBus:0];
    [self.audioEngine connect:newNode to:self.audioEnvironmentNode format:inputFormat];
    
    AVAudioFile* audioFileToPlay = _hornSound;
    switch (type.intValue) {
        case 1:
            audioFileToPlay = _hornSound;
            break;
        case 2:
            audioFileToPlay = _personSound;
            break;
        case 3:
            audioFileToPlay = _bottleSound;
            break;
        case 4:
            audioFileToPlay = _chairSound;
            break;
        case 5:
            audioFileToPlay = _laptopSound;
            break;
        default:
            audioFileToPlay = _hornSound;
    }
    
    [newNode scheduleFile:audioFileToPlay atTime:nil completionHandler:nil];
    
    newNode.position = AVAudioMake3DPoint(x, y, z);
    newNode.reverbBlend = 0.5;
    newNode.volume = distance;
    
    [_audioPlayerNodeArray addObject:newNode];
    [newNode play];
}

- (void)setupAudio {
    // 1. Set up AVAudioEngine
    self.audioEngine = [[AVAudioEngine alloc] init];
    
    // 2. Create audio environment node
    self.audioEnvironmentNode = [[AVAudioEnvironmentNode alloc] init];
    [self.audioEngine attachNode:self.audioEnvironmentNode];
    
    // 3. Connect environment node to main mixer
    AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
    
    AVAudioFormat *outputFormat = [mainMixer outputFormatForBus:0];
    [self.audioEngine connect:self.audioEnvironmentNode to:mainMixer format:outputFormat];
    
    // 4. Create audio player node
    
    self.audioPlayerNode = [[AVAudioPlayerNode alloc] init];
    [self.audioEngine attachNode:self.audioPlayerNode];
    
    // 5. Connect audio player node to environment node
    AVAudioFormat *inputFormat = [self.audioEnvironmentNode inputFormatForBus:0];
    [self.audioEngine connect:self.audioPlayerNode to:self.audioEnvironmentNode format:inputFormat];
    
    // 6. Load audio file
    NSURL *audioFileURL = [[NSBundle mainBundle] URLForResource:@"mixkit-clown-horn-at-circus-715" withExtension:@"wav"];
    self.hornSound = [[AVAudioFile alloc] initForReading:audioFileURL error:nil];
    
    audioFileURL = [[NSBundle mainBundle] URLForResource:@"person" withExtension:@"wav"];
    self.personSound = [[AVAudioFile alloc] initForReading:audioFileURL error:nil];
    
    audioFileURL = [[NSBundle mainBundle] URLForResource:@"bottle" withExtension:@"wav"];
    self.bottleSound = [[AVAudioFile alloc] initForReading:audioFileURL error:nil];
    
    audioFileURL = [[NSBundle mainBundle] URLForResource:@"laptop" withExtension:@"wav"];
    self.laptopSound = [[AVAudioFile alloc] initForReading:audioFileURL error:nil];

    audioFileURL = [[NSBundle mainBundle] URLForResource:@"chair" withExtension:@"wav"];
    self.chairSound = [[AVAudioFile alloc] initForReading:audioFileURL error:nil];

    
    // 7. Schedule the audio file to play
//    [self.audioPlayerNode scheduleFile:self.hornSound atTime:nil completionHandler:^{
//            [self.audioPlayerNode scheduleFile:self.hornSound atTime:nil completionHandler:nil];
//            self.audioPlayerNode.position = AVAudioMake3DPoint(-1.0, 0.0, 0.0);
//            self.audioPlayerNode.reverbBlend = 0.5;
//            [self.audioPlayerNode play];
//    }];
//
    // 8. Start the audio engine
    [self.audioEngine startAndReturnError:nil];
    
//    [self addNodeAndPlayWith:1.0 y:0.0 z:0.0 distance:1.0 type:[NSNumber numberWithInt:1]];
//    [NSThread sleepForTimeInterval:1];
//    [self addNodeAndPlayWith:-1.0 y:0.0 z:0.0 distance:0.1 type:[NSNumber numberWithInt:1]];

//
//
//    // 9. Play the audio file
//    [self.audioPlayerNode play];
//
//    // 10. Set the position and orientation of the audio player node
//    self.audioPlayerNode.position = AVAudioMake3DPoint(1.0, 0.0, 0.0);
//    self.audioPlayerNode.reverbBlend = 0.5;
}

- (void)audioPlayerNodeDidFinishPlaying:(AVAudioPlayerNode *)player successfully:(BOOL)flag {
  if (flag) {
    NSLog(@"Audio player node finished playing successfully");
  } else {
    NSLog(@"Audio player node finished playing with error");
  }
}


@end
