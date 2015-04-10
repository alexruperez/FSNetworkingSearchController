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
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ARViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.viewHandler.refreshControl)
    {
        UIRefreshControl *refreshControl = UIRefreshControl.new;
        refreshControl.tintColor = self.searchDisplayController.searchResultsTableView.tintColor;
        refreshControl.layer.zPosition = -1;
        [refreshControl addTarget:self action:@selector(reloadData:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:refreshControl];
    }
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
    
    [self reloadData:self];
}

- (IBAction)reloadData:(id)sender
{
    [self.viewHandler reloadData:nil tableView:self.tableView completion:^{
        if ([sender respondsToSelector:NSSelectorFromString(@"endRefreshing")])
        {
            [sender endRefreshing];
        }
    }];
}

@end
