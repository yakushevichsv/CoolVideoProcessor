//
//  PlayVideoVC.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 5/13/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "PlayVideoVC.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface PlayVideoVC ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@end

@implementation PlayVideoVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //[self simulateImagePicker];
    //[self startBrowsingMediaFolder];
}
-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self simulateImagePicker];
}


-(void)simulateImagePicker
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup
                                                                            *group, BOOL *stop) {
        // Within the group enumeration block, filter to enumerate just videos.
        [group setAssetsFilter:[ALAssetsFilter allVideos]];
        // For this example, we're only interested in the first item.
        [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                                options:0
                             usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL
                                          *innerStop) {
                                 // The end of the enumeration is signaled by asset ==
                                 
                                 if (alAsset) {
                                 ALAssetRepresentation *representation = [alAsset
                                                                          defaultRepresentation];
                                 NSURL *url = [representation url];
                                     
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         MPMoviePlayerViewController *theMovie = [[MPMoviePlayerViewController alloc]
                                                                                  initWithContentURL:url];
                                         [theMovie.moviePlayer setShouldAutoplay:FALSE];
                                         [self presentMoviePlayerViewControllerAnimated:theMovie];
                                         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:)
                                                                                      name:MPMoviePlayerPlaybackDidFinishNotification object:theMovie.moviePlayer];
                                         
                                     });
                                     // 4 - Register for the playback finished notification
                                     
                                     
                                     
                                 // Do something interesting with the AV asset.
                             }
         }];
    }
                         failureBlock: ^(NSError *error) {
                             // Typically you should handle an error more gracefully than
                             NSLog(@"No groups");
                         }];
}

-(void)startBrowsingMediaFolder
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        return;
    }
    
    UIImagePickerController * controller =[UIImagePickerController new];
    controller.mediaTypes =@[(NSString *) kUTTypeMovie];//[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum	];
    
    for (NSString * curType in controller.mediaTypes)
    {
        if (CFStringCompare ((__bridge_retained CFStringRef)curType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
            controller.videoQuality = UIImagePickerControllerQualityTypeLow;
            break;
        }
        
    }
    controller.allowsEditing = NO;
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
    
}

/*  Notification called when the movie finished playing. */
- (void) moviePlayBackDidFinish:(NSNotification*)notification
{
    NSNumber *reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    MPMoviePlayerController* theMovie = [notification object];
    [theMovie stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:theMovie];
	switch ([reason integerValue])
	{
            /* The end of the movie was reached. */
		case MPMovieFinishReasonPlaybackEnded:
            /*
             Add your code here to handle MPMovieFinishReasonPlaybackEnded.
             */
            [self.navigationController popViewControllerAnimated:YES];
            [self dismissMoviePlayerViewControllerAnimated];
			break;
            
            /* An error was encountered during playback. */
		case MPMovieFinishReasonPlaybackError:
            NSLog(@"An error was encountered during playback");
            /*[self performSelectorOnMainThread:@selector(displayError:) withObject:[[notification userInfo] objectForKey:@"error"]
                                waitUntilDone:NO];
            [self removeMovieViewFromViewHierarchy];
            [self removeOverlayView];
            [self.backgroundView removeFromSuperview];*/
			break;
            
            /* The user stopped playback. */
		case MPMovieFinishReasonUserExited:
            /*[self removeMovieViewFromViewHierarchy];
            [self removeOverlayView];
            [self.backgroundView removeFromSuperview];*/
            [self.navigationController popViewControllerAnimated:YES];
            [self dismissMoviePlayerViewControllerAnimated];
			break;
            
		default:
			break;
	}
}

/*
-(void)moviePlayBackDidFinish:(NSNotification*)aNotification {
    [self dismissMoviePlayerViewControllerAnimated];
    MPMoviePlayerController* theMovie = [aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification object:theMovie];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}
*/

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
    NSLog(@"Dictionary %@",info.description);
   [self dismissPicker:picker animated:NO];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissPicker:picker animated:YES];
}

-(void)dismissPicker:(UIImagePickerController*)picker animated:(BOOL)animated
{
    [picker  dismissViewControllerAnimated:animated completion:nil];
}

@end
