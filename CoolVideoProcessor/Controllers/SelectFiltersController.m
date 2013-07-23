//
//  SelectFiltersController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 7/23/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "SelectFiltersController.h"
#import "AssetItem.h"
@interface SelectFiltersController ()
@property (nonatomic,strong) CIContext * context;
@end

@implementation SelectFiltersController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.context = [CIContext contextWithOptions:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	CIImage * image = [CIImage imageWithCGImage:self.item.image.CGImage];
    CIFilter * filter = [ CIFilter filterWithName:@"CISepiaTone"];
    [filter setValue:image forKey:kCIInputImageKey];
    [filter setValue:@(0.8f) forKey:@"inputIntensity"];
    CIImage * result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage =[self.context createCGImage:result fromRect:[result extent]];
    UIImage * resImage = [UIImage imageWithCGImage:cgImage];
    UIImageView * imageView = [[UIImageView alloc] initWithImage:resImage];
    imageView.bounds =CGRectMake(0,0,resImage.size.width,resImage.size.height);
    imageView.center =self.view.center;
    [imageView sizeToFit];
    [self.view addSubview:imageView];
}

@end
