//
//  PlayerView.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/4/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation PlayerView
+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
@end