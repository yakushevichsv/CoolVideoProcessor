//
//  PositionViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 6/28/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "PositionViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface PositionViewController ()
{
    NSUInteger _index;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) ALAssetsLibrary * library;
@property (nonatomic,strong) NSMutableArray * urls;
@end

@implementation PositionViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}


-(void)dealloc{
    self.library = nil;
}

-(void)setup
{
    self.library = [ALAssetsLibrary new];
}

-(void)setDataDictionary:(NSDictionary *)dataDictionary
{
    if (![_dataDictionary isEqualToDictionary:dataDictionary])
    {
        _dataDictionary = dataDictionary;
        NSMutableArray * array = [NSMutableArray arrayWithCapacity:[_dataDictionary[@"images"] count] +[_dataDictionary[@"video"] count]];
        
        self.urls  = array;
        _index = 0;
        [self.tableView reloadData];
    }
}
@end
