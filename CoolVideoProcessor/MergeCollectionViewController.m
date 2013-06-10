//
//  MergeCollectionViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/10/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "MergeCollectionViewController.h"

#define NUMBER_OF_SECTIONS 2

@interface MergeCollectionViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>

@end

@implementation MergeCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)setFiles:(UICollectionView *)files
{
    if (![_files isEqual:files])
    {
        files.dataSource = self;
        files.delegate = self;
        _files =files;
    }
}


#pragma mark - UICollectionViewDataSource 

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if ([self.files isEqual:collectionView])
    {
        return NUMBER_OF_SECTIONS;
    }
    return NSIntegerMin;
}

@end
