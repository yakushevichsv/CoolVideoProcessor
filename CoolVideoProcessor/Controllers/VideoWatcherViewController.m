//
//  VideoWatcherViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/20/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "VideoWatcherViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VideoWatcherViewController ()
@property (nonatomic,strong) MPMoviePlayerViewController * controller;
@end

@implementation VideoWatcherViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}


-(void)setMovieURL:(NSURL *)movieURL
{
    if (![_movieURL isEqual:movieURL])
    {
        _movieURL = movieURL;
        
        if (!movieURL) return ;
        
    }
}

-(void)initMoviePlayer
{
    self.controller= [[MPMoviePlayerViewController alloc]initWithContentURL:self.movieURL];
    self.controller.moviePlayer.shouldAutoplay = YES;
    
    [[NSNotificationCenter defaultCenter]removeObserver:self.controller name:MPMoviePlayerPlaybackDidFinishNotification object:self.controller.moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.controller.moviePlayer];
    self.controller.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    [self.controller.moviePlayer prepareToPlay];
    
    [self presentPlayer];
}

-(void)presentPlayer
{
    if (self.isViewLoaded && self.controller)
    {
        [self.view addSubview:self.controller.moviePlayer.view];
        //self.controller = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	// Do any additional setup after loading the view.
    if (!self.controller)
    [self initMoviePlayer];
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
        self.controller = nil;
    }
    
}

- (IBAction)unwindFromConfirmationForm:(UIStoryboardSegue *)segue {
    
     //[self dismissMoviePlayerViewControllerAnimated];
}

@end
