//
//  AssetsLibrary.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AssetItem.h"
#import "AssetsLibrary.h"
#import "AVAssetItem.h"
#import "ALAssetItem.h"

const char * alQueueName = "coolvideoprocessor.s.assetslibrary.queue";

@interface AssetsLibrary ()

@property(readonly, strong) dispatch_queue_t assetItemsQueue;

@property(readonly, strong) dispatch_group_t libraryGroup;
@property(readonly, strong) dispatch_queue_t libraryQueue;

@end

@implementation AssetsLibrary

#pragma mark - Init methods

-(id)initWithLibraryChangedHandler:(alVoidCompletitionBlock)completitionBlock
{
    if (self = [super init])
    {
        _videoAssetItems = [NSMutableArray array];
        _imageAssetItems =[NSMutableArray array];
        _assetItemsQueue = dispatch_queue_create(alQueueName, DISPATCH_QUEUE_SERIAL);
        _libraryGroup = dispatch_group_create();
        _libraryQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        _completitionBlock=completitionBlock;
        [[NSNotificationCenter defaultCenter] addObserverForName:ALAssetsLibraryChangedNotification
														  object:nil
														   queue:[NSOperationQueue mainQueue]
													  usingBlock:^(NSNotification *block){
                                                          completitionBlock();
                                                      }];
        
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}

#pragma mark - private methods

-(void)addURL:(NSURL*)url type:(AssetItemType)type mediaType:(AssetItemMediaType)mediaType
{
    if (!url) return;
    
    dispatch_async(self.assetItemsQueue, ^{
        id assetItemClass;
        if (type == AssetItemTypeAV)
        {
            assetItemClass = [AVAssetItem alloc];
        }
        else if (type == AssetItemTypeAL)
        {
            assetItemClass = [ALAssetItem alloc];
        }
        else
            assetItemClass = nil;
        if (assetItemClass)
        {
            NSMutableArray * assetItems = mediaType == AssetItemMediaTypeVideo ? self.videoAssetItems : self.imageAssetItems;
            [assetItems addObject:[assetItemClass initWithURL:url mediaType:mediaType]];
        }
    });
}

#pragma mark - public methods

-(void)loadLibraryWithCompletitionBlock:(alVoidCompletitionBlock)completitionBlock
{
    // Load content using the Media Library and AssetLibrary APIs, also check for content included in the application bundle
	[self.videoAssetItems removeAllObjects];
    [self.imageAssetItems removeAllObjects];
    
	[self buildMediaLibrary:AssetItemMediaTypeVideo];
    [self buildMediaLibrary:AssetItemMediaTypeImage];
    
	[self buildAssetLibrary:AssetItemMediaTypeVideo];
    [self buildAssetLibrary:AssetItemMediaTypeImage];
	
	dispatch_group_notify(self.libraryGroup, self.libraryQueue, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			completitionBlock();
		});
	});
}

#pragma mark - iPod Library

- (void)buildMediaLibrary:(AssetItemMediaType)mediaType
{
	dispatch_group_async(self.libraryGroup, self.libraryQueue, ^{
		NSLog(@"started building media library...");
		
		// Search for video content in the Media Library
#if  __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
        NSInteger number = mediaType ==AssetItemMediaTypeVideo ? MPMediaTypeAnyVideo : MPMediaTypeAnyAudio;
		NSNumber *videoTypeNum = [NSNumber numberWithInteger:number];
#endif
		MPMediaPropertyPredicate *videoPredicate = [MPMediaPropertyPredicate predicateWithValue:videoTypeNum forProperty:MPMediaItemPropertyMediaType];
		MPMediaQuery *videoQuery = [[MPMediaQuery alloc] init];
		[videoQuery addFilterPredicate: videoPredicate];
		NSArray *items = [videoQuery items];
		
		for (MPMediaItem *mediaItem in items)
			[self addURL:[mediaItem valueForProperty:MPMediaItemPropertyAssetURL] type:AssetItemTypeAV mediaType:mediaType];
		
		NSLog(@"done building media library...");
	});
}

- (void)buildAssetLibrary:(AssetItemMediaType)mediaType
{
	NSLog(@"started building asset library...");
	
	dispatch_group_enter(self.libraryGroup);
	
	ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
	
	// Enumerate through all the groups in the Asset Library
	[assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
								usingBlock:
	 ^(ALAssetsGroup *group, BOOL *stop)
	 {
		 if (group != nil)
		 {
			 // Filter by groups that contain video
			 ALAssetsFilter * filter;
             if (mediaType == AssetItemMediaTypeVideo ) {
                 filter = [ALAssetsFilter allVideos];
             }
             else if (mediaType == AssetItemMediaTypeImage )
             {
                 filter =[ALAssetsFilter allPhotos];
             }
             else filter = nil;
             
             [group setAssetsFilter:filter];
			 [group enumerateAssetsUsingBlock:
			  ^(ALAsset *asset, NSUInteger index, BOOL *stop)
			  {
				  if (asset)
					  [self addURL:[[asset defaultRepresentation] url] type:AssetItemTypeAL mediaType:mediaType];
			  }];
		 }
		 else
		 {
			 dispatch_group_leave(self.libraryGroup);
			 NSLog(@"done building asset library...");
		 }
	 }
							  failureBlock:^(NSError *error)
	 {
		 dispatch_group_leave(self.libraryGroup);
		 NSLog(@"error enumerating AssetLibrary groups %@\n", error);
	 }];
	
}


#pragma mark - Static methods

+(void)exportComposition:(AVMutableComposition*)composition aURL:(NSURL*)url competition:(alCompletitionBlock)competition
{
    
    NSArray * exportPresets = @[AVAssetExportPresetHighestQuality,AVAssetExportPresetMediumQuality,AVAssetExportPresetLowQuality];
    
    
    
    NSArray * presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:composition];
    
    AVAssetExportSession *exportSession;
    
    for (NSString * curPreset in exportPresets)
    {
        if ([presets containsObject:curPreset])
        {
            exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:curPreset];
            
    
            exportSession.outputURL = url;
            exportSession.outputFileType = @"com.apple.quicktime-movie"; //TODO: figure out if it is movie asset, or audio..
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status) {
            case AVAssetExportSessionStatusFailed:{
                NSLog (@"FAIL");
                
                NSError * error =  exportSession.error;
                dispatch_async(dispatch_get_main_queue(), ^{
                    competition(error);
                });
                break;
            }
            case AVAssetExportSessionStatusCompleted: {
                NSLog (@"SUCCESS");
                dispatch_async(dispatch_get_main_queue(), ^{
                    competition(nil);
                });
                break;
            }
        };
    }];
            return;
        }
    }
    NSLog(@"Preset is not supported!");
}

+(void)exportComposition:(AVMutableComposition*)composition atPath:(NSString*)path competition:(alCompletitionBlock)competition
{
    [self exportComposition:composition aURL:[NSURL URLWithString:path] competition:competition];
}

@end
