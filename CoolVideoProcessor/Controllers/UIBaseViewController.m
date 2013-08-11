//
//  UIBaseViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/21/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "UIBaseViewController.h"
#import "UIImage+Scale.h"
#import <MediaPlayer/MediaPlayer.h>
@interface UIBaseViewController ()
@end

@implementation UIBaseViewController

-(void)displayMovieByURL:(NSURL*)url
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




-(void)displayImage:(UIImage*)image
{
    UIViewController * controller = [UIViewController new];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];

    controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    
    image = [image scaleToSizeWithAspectRatio:controller.view.bounds.size];
    UIImageView * imageView = [[UIImageView alloc]initWithImage:image];
    
    CGFloat yOffset = (controller.view.bounds.size.height - image.size.height)*0.5;
    CGFloat xOffset = (controller.view.bounds.size.width - image.size.width)*0.5;
    imageView.transform= CGAffineTransformMakeTranslation(xOffset, yOffset);

    
    [controller.view addSubview:imageView];
    
    
    [self presentViewController:navController animated:YES completion:nil];
}

-(void)donePressed
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
