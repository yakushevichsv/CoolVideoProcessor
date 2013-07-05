//
//  PlayerViewController.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/4/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer,AVPlayerItem,PlayerView;

@interface PlayerViewController : UIViewController
@property (nonatomic) AVPlayer * player;
@property (nonatomic) AVPlayerItem * playerItem;

@property (nonatomic,weak) IBOutlet PlayerView * playerView;
@property (nonatomic,weak) IBOutlet UIButton * btnPlay;

@property (nonatomic,strong) NSURL * url;

@end
