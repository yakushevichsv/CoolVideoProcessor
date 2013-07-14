//
//  ALAssetItem.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/14/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "AssetItem.h"

@interface ALAssetItem : AssetItem
-(id)initWithURL:(NSURL *)url mediaType:(AssetItemMediaType)mediaType;
@end
