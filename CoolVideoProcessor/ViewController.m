//
//  ViewController.m
//  CoolVideoProcessor
//
//  Created by Siarhei Yakushevich on 5/12/13.
//  Copyright (c) 2013 Siarhei Yakushevich. All rights reserved.
//

#import "ViewController.h"
#import "PlayVideoVC.h"

#define SELECT_AND_PLAY @"selectAndPlayVideo"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SELECT_AND_PLAY])
    {
        if ([segue.destinationViewController isKindOfClass:[PlayVideoVC class]])
        {
            PlayVideoVC * destVC = (PlayVideoVC*)segue.destinationViewController;
        }
    }
}

@end
