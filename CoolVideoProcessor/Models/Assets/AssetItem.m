//
//  AssetItem.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/7/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "AssetItem.h"

@implementation AssetItem

-(id)initWithURL:(NSURL *)url type:(AssetItemType)type mediaType:(AssetItemMediaType)mediaType
{
    if (self=[super init])
    {
        _url = url;
        _type = type;
        _mediaType = mediaType;
    }
    return self;
}

- (NSString *)loadTitleWithCompletitionHandler:(completitionBlock)completionHandler
{
    return self.title;
}

- (UIImage *)loadThumbnailWithCompletitionHandler:(completitionBlock)completionHandler
{
    return self.image;
}


-(NSTimeInterval)loadDurationWithCompletitionHandler:(completitionBlock)completionHandler
{
    return self.duration;
}

-(void)flush
{
    self.image = nil;
    self.done = FALSE;
    self.title = nil;
}

@end
