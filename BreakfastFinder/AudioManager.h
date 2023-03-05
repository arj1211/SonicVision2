//
//  AudioManager.h
//  BreakfastFinder
//
//  Created by Dhruv Mathur on 2023-03-05.
//  Copyright © 2023 Apple. All rights reserved.
//

#ifndef AudioManager_h
#define AudioManager_h

@import Foundation;
@import AVFoundation;
@import SceneKit;

@interface AudioEngine : NSObject

- (void)setupAudio;
- (void)addNodeAndPlayWith:(Float32)x y:(Float32)y z:(Float32)z distance:(Float32)distance type:(NSNumber*)type;

@end

#endif /* AudioManager_h */
