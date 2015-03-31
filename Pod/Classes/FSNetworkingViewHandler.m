//
//  FSNetworkingViewHandler.m
//  FSNetworkingSearchController
//
//  Created by alexruperez on 30/3/15.
//
//

#import "FSNetworkingViewHandler.h"
#import "FSNetworkingSearchController.h"


CGFloat const FSNVHDefaultCellHeight = 60.0f;
FSNetworkingImageSize const FSNVHDefaultImageSize = FSNetworkingImageSize88;
UIViewContentMode const FSNVHDefaultImageContentMode = UIViewContentModeCenter;
NSURLRequestCachePolicy const FSNVHDefaultCachePolicy = NSURLRequestReturnCacheDataElseLoad;
NSTimeInterval const FSNVHDefaultTimeout = 30.0f;
CGFloat const FSNVHDefaultMinimumScaleFactor = 0.5f;
NSString * const FSNVHDefaultCellReuseIdentifier = @"Cell";

@interface FSNetworkingViewHandler ()
{
    NSMutableArray *_venues;
    NSMutableDictionary *_cachedImages;
}

@property (strong, nonatomic, readonly) NSMutableArray *venues;
@property (strong, nonatomic, readonly) NSMutableDictionary *cachedImages;
@property (strong, nonatomic, readonly) UISearchDisplayController *searchDisplayController;
@property (strong, nonatomic, readonly) NSString *lastSearchText;

@end

@implementation FSNetworkingViewHandler

- (NSMutableArray *)venues
{
    if (!_venues)
    {
        _venues = NSMutableArray.new;
    }
    
    return _venues;
}

- (NSMutableDictionary *)cachedImages
{
    if (!_cachedImages)
    {
        _cachedImages = NSMutableDictionary.new;
    }
    
    return _cachedImages;
}

- (CGFloat)cellHeight
{
    if (_cellHeight == 0.0f)
    {
        _cellHeight = FSNVHDefaultCellHeight;
    }
    
    return _cellHeight;
}

- (UIViewContentMode)imageContentMode
{
    if (!_imageContentMode)
    {
        _imageContentMode = FSNVHDefaultImageContentMode;
    }
    
    return _imageContentMode;
}

- (FSNetworkingImageSize)imageSize
{
    if (!_imageSize)
    {
        _imageSize = FSNVHDefaultImageSize;
    }
    
    return _imageSize;
}

#pragma mark - Public Methods

- (IBAction)reloadData:(id)sender
{
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text tableView:self.searchDisplayController.searchResultsTableView completion:^{
        if ([sender respondsToSelector:NSSelectorFromString(@"endRefreshing")])
        {
            [sender endRefreshing];
        }
    }];
}

#pragma mark - UISearchDisplayDelegate

- (void)filterContentForSearchText:(NSString*)searchText tableView:(UITableView *)tableView completion:(void (^)(void))completion
{
    if (![self.lastSearchText isEqualToString:searchText])
    {
        _lastSearchText = searchText;
        [FSNetworkingSearchController search:searchText completion:^(NSArray *venues, NSError *error) {
            [self.venues removeAllObjects];
                
            [self.venues addObjectsFromArray:venues];
            
            if ([tableView respondsToSelector:NSSelectorFromString(@"reloadData")])
            {
                [tableView reloadData];
            }
            
            if (completion)
            {
                completion();
            }
        }];
    }
    else if (completion)
    {
        completion();
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString tableView:controller.searchResultsTableView completion:nil];
    
    return NO;
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    if (!self.searchDisplayController)
    {
        _searchDisplayController = controller;
        if (!self.shouldHideRefreshControl)
        {
            UIRefreshControl *refreshControl = UIRefreshControl.new;
            refreshControl.tintColor = controller.searchResultsTableView.tintColor;
            [refreshControl addTarget:self action:@selector(reloadData:) forControlEvents:UIControlEventValueChanged];
            [controller.searchResultsTableView addSubview:refreshControl];
        }
    }
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    [FSNetworkingSearchController cancelPendingConnections];
    
    [self.venues removeAllObjects];
    
    [controller.searchResultsTableView reloadData];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self filterContentForSearchText:searchController.searchBar.text tableView:searchController.searchResultsController completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.venues.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FSNVHDefaultCellReuseIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:FSNVHDefaultCellReuseIdentifier];
    }
    
    cell.textLabel.text = self.venues[indexPath.row][@"name"];
    cell.textLabel.minimumScaleFactor = FSNVHDefaultMinimumScaleFactor;
    
    NSDictionary *location = self.venues[indexPath.row][@"location"];
    NSMutableString *detail = NSMutableString.new;
    if (location[@"address"])
    {
        [detail appendString:location[@"address"]];
        [detail appendString:@"\n"];
    }
    if (location[@"distance"])
    {
        [detail appendFormat:@"%d", [location[@"distance"] intValue]];
        [detail appendString:NSLocalizedString(@" m", @"Meter unit symbol")];
    }
    cell.detailTextLabel.text = detail.copy;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.minimumScaleFactor = FSNVHDefaultMinimumScaleFactor;
    
    cell.imageView.image = nil;
    
    NSDictionary *primary = [self primaryCategory:self.venues[indexPath.row]];
    
    if (primary)
    {
        [self tableView:tableView setImageForCell:cell withCategory:primary];
    }
    
    return cell;
}

- (NSDictionary *)primaryCategory:(NSDictionary *)venue
{
    NSArray *categories = venue[@"categories"];
    NSDictionary *primary = nil;
    
    for (NSDictionary *category in categories)
    {
        if (!primary)
        {
            primary = category;
        }
        
        if ([category[@"primary"] boolValue] == 1)
        {
            primary = category;
        }
    }
    
    return primary;
}

+ (NSOperationQueue *)sharedImageRequestOperationQueue
{
    static NSOperationQueue *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NSOperationQueue alloc] init];
        sharedInstance.name = @"FSNVHImageRequestOperationQueue";
        sharedInstance.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });
    
    return sharedInstance;
}

- (void)tableView:(UITableView *)tableView setImageForCell:(UITableViewCell *)cell withCategory:(NSDictionary *)category
{
    NSString *identifier = category[@"id"];
    UIImage *image = self.cachedImages[identifier];
    
    if (image)
    {
        cell.imageView.image = image;
        cell.imageView.contentMode = self.imageContentMode;
    }
    else if (category[@"icon"])
    {
        NSString *urlString = [NSString stringWithFormat:@"%@%d%@", category[@"icon"][@"prefix"], self.imageSize, category[@"icon"][@"suffix"]];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        if (url)
        {
            [self downloadAndCacheImage:identifier fromURL:url completion:^{
                NSIndexPath *indexPath = [tableView indexPathForCell:cell];
                if (indexPath)
                {
                    cell.imageView.image = image;
                    cell.imageView.contentMode = self.imageContentMode;
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }];
        }
    }
}

- (void)downloadAndCacheImage:(NSString *)identifier fromURL:(NSURL *)url completion:(void (^)(void))completion
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:FSNVHDefaultCachePolicy timeoutInterval:FSNVHDefaultTimeout];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:FSNetworkingViewHandler.sharedImageRequestOperationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        UIImage *image = [UIImage imageWithData:data];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        if (image)
        {
            [self.cachedImages setObject:image forKey:identifier];
            
            [NSOperationQueue.mainQueue addOperationWithBlock:^{
                if (completion)
                {
                    completion();
                }
            }];
        }
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *venue = self.venues[indexPath.row];
    NSDictionary *primary = [self primaryCategory:venue];
    
    NSString *identifier = primary[@"id"];
    UIImage *image = self.cachedImages[identifier];
    
    self.selectHandler(venue, image);
}

@end
