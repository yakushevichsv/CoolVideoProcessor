//
//  FilterRepresentation.h
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 10/13/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CIFilter;

typedef NSObject FilterRepresentationCustomFilter;
typedef FilterRepresentationCustomFilter* FilterRepresentationCustomFilterPtr;
@interface FilterRepresentation : NSObject

@property (nonatomic, strong) CIFilter *ciFilter;
@property (nonatomic, strong) FilterRepresentationCustomFilterPtr customFilter;

-(BOOL)isCIFilter;
-(BOOL)isCustomFilter;

@end
