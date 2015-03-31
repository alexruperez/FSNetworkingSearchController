//
//  ARViewController.m
//  FSNetworkingSearchController
//
//  Created by alexruperez on 03/30/2015.
//  Copyright (c) 2014 alexruperez. All rights reserved.
//

#import "ARViewController.h"
#import <FSNetworkingSearchController/FSNetworkingSearchController.h>


@interface ARViewController ()

@property (weak, nonatomic) IBOutlet FSNetworkingViewHandler *viewHandler;

@end

@implementation ARViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!FSNetworkingSearchController.isLoggedIn)
    {
        [FSNetworkingSearchController loginWithCompletion:^(NSString *accessToken, NSError *error) {
            NSLog(@"%@", accessToken && !error ? @"Logged In!" : error.localizedDescription);
        }];
    }
    
    self.viewHandler.selectHandler = ^(NSDictionary *venue, UIImage *image) {
        NSLog(@"%@", venue);
    };
}

@end
