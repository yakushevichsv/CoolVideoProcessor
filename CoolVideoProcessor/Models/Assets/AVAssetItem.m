//
//  AVAssetItem.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "AVAssetItem.h"

@interface AVAssetItem()

@property(nonatomic, strong) AVAsset *videoAsset;
@property(nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property(nonatomic, strong) UIImage *image;

@property(nonatomic, readonly, unsafe_unretained) dispatch_once_t titleToken;
@property(nonatomic, readonly, unsafe_unretained) dispatch_once_t thumbnailToken;

@end

@implementation AVAssetItem

-(id)initWithURL:(NSURL *)url
{
    if (self =[super initWithURL:url])
    {
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.videoAsset = [[AVURLAsset alloc]initWithURL:self.url options:nil];
}

- (NSString *)loadTitleWithCompletitionHandler:(completitionBlock)completionHandler
{
    __unsafe_unretained __block AVAssetItem *weakSelf = (AVAssetItem *)self;
	dispatch_once(&_titleToken, ^{
		// Load the title from AVMetadataCommonKeyTitle
		NSLog(@"Loading title...");
		NSArray *key = [[NSArray alloc] initWithObjects:@"commonMetadata", nil];
		[weakSelf.videoAsset loadValuesAsynchronouslyForKeys:key
                                           completionHandler:^{
                                               NSArray *titles = [AVMetadataItem metadataItemsFromArray:weakSelf.videoAsset.commonMetadata withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon];
                                               if ([titles count] > 0)
                                               {
                                                   // If there is only one title, then use it
                                                   if ([titles count] == 1)
                                                   {
                                                       AVMetadataItem *titleItem = [titles objectAtIndex:0];
                                                       weakSelf.title = [titleItem stringValue];
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           NSLog(@"Loaded title for %@", weakSelf.title);
                                                           completionHandler();
                                                       });
                                                   }
                                                   else
                                                   {
                                                       // If there are more than one, search for the proper locale
                                                       NSArray *preferredLanguages = [NSLocale preferredLanguages];
                                                       for (NSString *currentLanguage in preferredLanguages)
                                                       {
                                                           NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:currentLanguage];
                                                           NSArray *titlesForLocale = [AVMetadataItem metadataItemsFromArray:titles withLocale:locale];
                                                           if ([titlesForLocale count] > 0)
                                                           {
                                                               weakSelf.title = [[titlesForLocale objectAtIndex:0] stringValue];
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   NSLog(@"Loaded title for %@", weakSelf.title);
                                                                   completionHandler();
                                                               });
                                                               break;
                                                           }
                                                       }
                                                   }
                                               }
                                           }];
	});
    
	return self.title;
}

- (UIImage *)loadThumbnailWithCompletitionHandler:(completitionBlock)completionHandler
{
    __unsafe_unretained __block AVAssetItem *weakSelf = (AVAssetItem *)self;
	dispatch_once(&_thumbnailToken, ^{
		[weakSelf.imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:kCMTimeZero]]
													  completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                                                          if (result == AVAssetImageGeneratorSucceeded)
                                                          {
                                                              weakSelf.image = [UIImage imageWithCGImage:image];
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                  NSLog(@"Loaded thumbnail for %@", weakSelf.title);
                                                                  completionHandler();
                                                              });
                                                          }
                                                          else if (result == AVAssetImageGeneratorFailed)
                                                          {
                                                              NSLog(@"couldn't generate thumbnail, error:%@", error);
                                                          }
                                                      }];
	});
	
	return self.image;
}

-(void)flush
{
    _thumbnailToken = nil;
    _titleToken = nil;
    self.image =nil;
    self.title = nil;
}


@end
