//
//  PlayerViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/4/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "PlayerViewController.h"
#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>

NSString * trackKey =@"tracks";
@interface PlayerViewController ()
@end

@implementation PlayerViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self matchUI];
}


static const NSString *ItemStatusContext;

-(void)matchUI
{
    self.btnPlay.enabled = self.player.currentItem.status == AVPlayerItemStatusReadyToPlay;
}

-(void)setUrl:(NSURL *)url
{
    if (![_url isEqual:url])
    {
        _url  = url;
        AVURLAsset * asset = [AVURLAsset assetWithURL:url];
        [asset loadValuesAsynchronouslyForKeys:@[trackKey] completionHandler:^{
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               NSError *error;
                               AVKeyValueStatus status = [asset statusOfValueForKey:trackKey
                                                                              error:&error];
                               if (status == AVKeyValueStatusLoaded) {
                                   self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                                   [self.playerItem addObserver:self forKeyPath:@"status"
                                                        options:0 context:&ItemStatusContext];
                                   [[NSNotificationCenter defaultCenter] addObserver:self
                                                                            selector:@selector(playerItemDidReachEnd:)
                                                                                name:AVPlayerItemDidPlayToEndTimeNotification
                                                                              object:self.playerItem];
                                   self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                                   [self.playerView setPlayer:self.player];
                               }
                               else {
                                   // You should deal with the error appropriately.
                                   NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                               }
                           });
        }];
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self matchUI];
                       });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

- (IBAction)play:(UIButton*)sender
{
    sender.hidden = !sender.isHidden;
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(playerItemDidReachEnd:)
         name:AVPlayerItemDidPlayToEndTimeNotification
         object:[self.player currentItem]];
        [self.player play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    [self.player seekToTime:kCMTimeZero];
    [UIView animateWithDuration:0.2 animations:^{
        self.btnPlay.hidden = !self.btnPlay.isHidden;
    }];
}
- (IBAction)tapped:(UITapGestureRecognizer *)sender{
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        if (self.btnPlay.isHidden)
        {
            [self.player pause];
            
            [UIView animateWithDuration:0.2 animations:^{
                self.btnPlay.hidden = !self.btnPlay.isHidden;
            }];
        }
    }
}

- (IBAction)unwindToRed:(UIStoryboardSegue *)unwindSegue
{
}


@end
