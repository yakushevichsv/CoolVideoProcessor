//
//  UIBaseViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/21/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "UIBaseViewController.h"
#import <MediaPlayer/MediaPlayer.h>
@interface UIBaseViewController ()

@end

@implementation UIBaseViewController

-(void)displayByURL:(NSURL*)url
{
    MPMoviePlayerViewController * controller= [[MPMoviePlayerViewController alloc]initWithContentURL:url];
    controller.moviePlayer.shouldAutoplay = YES;
    
    [[NSNotificationCenter defaultCenter]removeObserver:controller name:MPMoviePlayerPlaybackDidFinishNotification object:controller.moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:controller.moviePlayer];
    controller.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    [controller.moviePlayer prepareToPlay];
    
    [self presentMoviePlayerViewControllerAnimated:controller];
}

#pragma mark - MPMoviePlayer Delegate

-(void)playerPlaybackDidFinish:(NSNotification*)notification
{
    if ([notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue]==MPMovieFinishReasonUserExited)
    {
        [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:notification.object];
        
        MPMoviePlayerController * controller = ( MPMoviePlayerController * )notification.object;
        
        [controller pause];
        controller.initialPlaybackTime =-1;
        [controller stop];
        controller.initialPlaybackTime = -1;
        
        [self dismissMoviePlayerViewControllerAnimated];
        
    }
    
}

@end
