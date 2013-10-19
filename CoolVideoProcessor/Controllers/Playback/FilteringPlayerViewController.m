//
//  FilteringPlayerViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 10/6/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "FilteringPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "RosyWriterPreviewView.h"

static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

# define ONE_FRAME_DURATION 0.03

@interface FilteringPlayerViewController ()<AVPlayerItemOutputPullDelegate>
{
	AVPlayer *_player;
	dispatch_queue_t _myVideoOutputQueue;
	id _notificationToken;
    id _timeObserver;
    BOOL _playing;
    CIContext *g_context;
}

@property (nonatomic, weak) IBOutlet RosyWriterPreviewView *playerView;
@property (nonatomic, weak) IBOutlet UILabel *currentTime;
@property (nonatomic, weak) IBOutlet UIView *timeView;

@property CADisplayLink *displayLink;
@property AVPlayerItemVideoOutput *videoOutput;

@end

@implementation FilteringPlayerViewController

#pragma mark -

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_player = [[AVPlayer alloc] init];
    [self addTimeObserverToPlayer];
	
	// Setup CADisplayLink which will callback displayPixelBuffer: at every vsync.
	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
	[[self displayLink] addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[[self displayLink] setPaused:YES];
	
	// Setup AVPlayerItemVideoOutput with the required pixelbuffer attributes.
	NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
	self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
	_myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
	[[self videoOutput] setDelegate:self queue:_myVideoOutputQueue];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:AVPlayerItemStatusContext];
	[self addTimeObserverToPlayer];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self removeObserver:self forKeyPath:@"player.currentItem.status" context:AVPlayerItemStatusContext];
	[self removeTimeObserverFromPlayer];
	
	if (_notificationToken) {
		[[NSNotificationCenter defaultCenter] removeObserver:_notificationToken name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
		_notificationToken = nil;
	}
}


#pragma mark - Bar Button action

-(IBAction)barButtonPressed:(id)sender
{
    _playing =!_playing;
    NSMutableArray * items = [NSMutableArray arrayWithArray:self.toolbarItems];
    if (_playing)
    {
        CMTimeShow(_player.currentTime);
        if (CMTIME_IS_INVALID(_player.currentTime)  || CMTIME_COMPARE_INLINE(kCMTimeZero, ==, _player.currentTime))
        {
            [self.playerView setupGL];
            
            [self setupPlaybackForURL:self.url];
        }
        else
        {
            [items replaceObjectAtIndex:0 withObject:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(barButtonPressed:)]];
            self.navigationController.toolbar.items = items;
            [_player play];
        }
    }
    else
    {
        [items replaceObjectAtIndex:0 withObject:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(barButtonPressed:)]];
        self.navigationController.toolbar.items = items;
        [_player pause];
    }

   
}

#pragma mark - Playback setup

- (void)setupPlaybackForURL:(NSURL *)URL
{
	/*
	 Sets up player item and adds video output to it.
	 The tracks property of an asset is loaded via asynchronous key value loading, to access the preferred transform of a video track used to orientate the video while rendering.
	 After adding the video output, we request a notification of media change in order to restart the CADisplayLink.
	 */
	
	[[_player currentItem] removeOutput:self.videoOutput];
    
	AVPlayerItem *item = [AVPlayerItem playerItemWithURL:URL];
	AVAsset *asset = [item asset];
	
	[asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        
		if ([asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded) {
			NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
			if ([tracks count] > 0) {
				// Choose the first video track.
				AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
				[videoTrack loadValuesAsynchronouslyForKeys:@[@"preferredTransform"] completionHandler:^{
					
					if ([videoTrack statusOfValueForKey:@"preferredTransform" error:nil] == AVKeyValueStatusLoaded) {
						CGAffineTransform preferredTransform = [videoTrack preferredTransform];
						
						/*
                         The orientation of the camera while recording affects the orientation of the images received from an AVPlayerItemVideoOutput. Here we compute a rotation that is used to correctly orientate the video.
                         */
						self.playerView.preferredRotation = -1 * atan2(preferredTransform.b, preferredTransform.a);
						
						[self addDidPlayToEndTimeNotificationForPlayerItem:item];
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[item addOutput:self.videoOutput];
							[_player replaceCurrentItemWithPlayerItem:item];
							[self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
							[_player play];
						});
						
					}
					
				}];
			}
		}
		
	}];
	
}


- (void)stopLoadingAnimationAndHandleError:(NSError *)error
{
	if (error) {
        NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Cancel button title for animation load error");
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVPlayerItemStatusContext) {
		AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
		switch (status) {
			case AVPlayerItemStatusUnknown:
				break;
			case AVPlayerItemStatusReadyToPlay:
				self.playerView.presentationRect = [[_player currentItem] presentationSize];
				break;
			case AVPlayerItemStatusFailed:
				[self stopLoadingAnimationAndHandleError:[[_player currentItem] error]];
				break;
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)addDidPlayToEndTimeNotificationForPlayerItem:(AVPlayerItem *)item
{
	if (_notificationToken)
		_notificationToken = nil;
	
	/*
     Setting actionAtItemEnd to None prevents the movie from getting paused at item end. A very simplistic, and not gapless, looped playback.
     */
	_player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
	_notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:item queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		// Simple item playback rewind.
		[[_player currentItem] seekToTime:kCMTimeZero];
	}];
}

- (void)syncTimeLabel
{
	double seconds = CMTimeGetSeconds([_player currentTime]);
	if (!isfinite(seconds)) {
		seconds = 0;
	}
	
	int secondsInt = round(seconds);
	int minutes = secondsInt/60;
	secondsInt -= minutes*60;
	
	self.currentTime.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
	self.currentTime.textAlignment = NSTextAlignmentCenter;
    
	self.currentTime.text = [NSString stringWithFormat:@"%.2i:%.2i", minutes, secondsInt];
}

- (void)addTimeObserverToPlayer
{
	/*
	 Adds a time observer to the player to periodically refresh the time label to reflect current time.
	 */
    if (_timeObserver)
        return;
    /*
     Use __weak reference to self to ensure that a strong reference cycle is not formed between the view controller, player and notification block.
     */
    __weak FilteringPlayerViewController* weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 10) queue:dispatch_get_main_queue() usingBlock:
                     ^(CMTime time) {
                         [weakSelf syncTimeLabel];
                     }];
}

- (void)removeTimeObserverFromPlayer
{
    if (_timeObserver)
    {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

-(UIImage *)applyFilter:(CVPixelBufferRef)beginImage
{
    CIImage * tempImage = [CIImage imageWithCVPixelBuffer:beginImage];
    
    //CVPixelBufferRelease(beginImage);
    CIFilter * filter = [CIFilter filterWithName:@"CISepiaTone" keysAndValues: kCIInputImageKey, tempImage, nil];
    
    [filter setValue:@(0.8) forKey:@"InputIntensity"];
    
    CIImage *outputImage = filter.outputImage;
    UIImage * newImg = [UIImage imageWithCIImage:outputImage];
    
    return newImg;
}

#pragma mark - CADisplayLink Callback

- (void)displayLinkCallback:(CADisplayLink *)sender
{
	/*
	 The callback gets called once every Vsync.
	 Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
	 This pixel buffer can then be processed and later rendered on screen.
	 */
	CMTime outputItemTime = kCMTimeInvalid;
	
	// Calculate the nextVsync time which is when the screen will be refreshed next.
	CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
	
	outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
	
	if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
		CVPixelBufferRef pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        NSLog(@"%d",(NSUInteger)CVPixelBufferGetPixelFormatType(pixelBuffer));
        UIImage * image = [self applyFilter:pixelBuffer];
        
        if (!g_context)
        {
            EAGLContext *myEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
            NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
            [options setObject: [NSNull null] forKey: kCIContextWorkingColorSpace];
            g_context = [CIContext contextWithEAGLContext:myEAGLContext options:options];
        }
        NSParameterAssert(image.CIImage);
        
        [g_context render:image.CIImage toCVPixelBuffer:pixelBuffer];
        image = nil;
        
        [[self playerView] displayPixelBuffer:pixelBuffer];
	}
}

#pragma mark - AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
	// Restart display link.
	[[self displayLink] setPaused:NO];
}


- (IBAction)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
    self.navigationController.navigationBar.hidden =!self.navigationController.navigationBar.isHidden;
    self.navigationController.toolbar.hidden = !self.navigationController.toolbar.isHidden;
    
    if (self.navigationController.navigationBar.isHidden)
        [self barButtonPressed:nil];
}

#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint point = [touch locationInView:self.view];
    
    return !CGRectContainsPoint(self.navigationController.toolbar.frame,point);
    
}


@end
