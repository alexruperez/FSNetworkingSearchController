//
//  FSNetworkingViewHandler.m
//  FSNetworkingSearchController
//
//  Created by alexruperez on 30/3/15.
//
//

#import "FSNetworkingViewHandler.h"
#import "FSNetworkingSearchController.h"


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

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)init
{
    self = super.init;
    
    if (self)
    {
        self.cellHeight = 60.0f;
        self.refreshControl = YES;
        self.categoryImage = YES;
        self.addressDetail = YES;
        self.distanceDetail = YES;
        self.textLabelColor = UIColor.blackColor;
        self.detailLabelColor = UIColor.lightGrayColor;
        self.imageContentMode = UIViewContentModeScaleAspectFit;
        self.imageSize = FSNetworkingImageSize44;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = super.init;
    
    if (self)
    {
        self.cellHeight = [decoder decodeFloatForKey:NSStringFromSelector(@selector(cellHeight))];
        self.refreshControl = [decoder decodeBoolForKey:NSStringFromSelector(@selector(refreshControl))];
        self.categoryImage = [decoder decodeBoolForKey:NSStringFromSelector(@selector(categoryImage))];
        self.addressDetail = [decoder decodeBoolForKey:NSStringFromSelector(@selector(addressDetail))];
        self.distanceDetail = [decoder decodeBoolForKey:NSStringFromSelector(@selector(distanceDetail))];
        self.textLabelColor = [decoder decodeObjectForKey:NSStringFromSelector(@selector(textLabelColor))];
        self.detailLabelColor = [decoder decodeObjectForKey:NSStringFromSelector(@selector(detailLabelColor))];
        self.imageContentMode = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(imageContentMode))];
        self.imageSize = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(imageSize))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeFloat:self.cellHeight forKey:NSStringFromSelector(@selector(cellHeight))];
    [coder encodeBool:self.refreshControl forKey:NSStringFromSelector(@selector(refreshControl))];
    [coder encodeBool:self.categoryImage forKey:NSStringFromSelector(@selector(categoryImage))];
    [coder encodeBool:self.addressDetail forKey:NSStringFromSelector(@selector(addressDetail))];
    [coder encodeBool:self.distanceDetail forKey:NSStringFromSelector(@selector(distanceDetail))];
    [coder encodeObject:self.textLabelColor forKey:NSStringFromSelector(@selector(textLabelColor))];
    [coder encodeObject:self.detailLabelColor forKey:NSStringFromSelector(@selector(detailLabelColor))];
    [coder encodeInteger:self.imageContentMode forKey:NSStringFromSelector(@selector(imageContentMode))];
    [coder encodeInteger:self.imageSize forKey:NSStringFromSelector(@selector(imageSize))];
}

- (id)copyWithZone:(NSZone *)zone
{
    FSNetworkingViewHandler *viewHandler = [[FSNetworkingViewHandler allocWithZone:zone] init];
    
    if (viewHandler)
    {
        viewHandler.selectHandler = self.selectHandler;
        viewHandler.cellHeight = self.cellHeight;
        viewHandler.refreshControl = self.refreshControl;
        viewHandler.categoryImage = self.categoryImage;
        viewHandler.addressDetail = self.addressDetail;
        viewHandler.distanceDetail = self.distanceDetail;
        viewHandler.textLabelColor = self.textLabelColor;
        viewHandler.detailLabelColor = self.detailLabelColor;
        viewHandler.imageContentMode = self.imageContentMode;
        viewHandler.imageSize = self.imageSize;
    }
    
    return viewHandler;
}

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

#pragma mark - Public Methods

- (IBAction)reloadData:(id)sender
{
    [self reloadData:self.searchDisplayController.searchBar.text tableView:self.searchDisplayController.searchResultsTableView completion:^{
        if ([sender respondsToSelector:NSSelectorFromString(@"endRefreshing")])
        {
            [sender endRefreshing];
        }
    }];
}

- (void)reloadData:(NSString*)searchText tableView:(UITableView *)tableView completion:(void (^)(void))completion
{
    if (!searchText.length || ![self.lastSearchText isEqualToString:searchText])
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

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self reloadData:searchString tableView:controller.searchResultsTableView completion:nil];
    
    return NO;
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    if (!self.searchDisplayController)
    {
        _searchDisplayController = controller;
        if (self.refreshControl)
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
    [self reloadData:searchController.searchBar.text tableView:searchController.searchResultsController.view completion:nil];
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
    
    if (self.venues.count > indexPath.row)
    {
        NSDictionary *venue = self.venues[indexPath.row];
        
        cell.textLabel.text = venue[@"name"];
        cell.textLabel.minimumScaleFactor = FSNVHDefaultMinimumScaleFactor;
        cell.textLabel.textColor = self.textLabelColor;
        
        NSDictionary *location = venue[@"location"];
        NSMutableString *detail = NSMutableString.new;
        NSString *address = location[@"address"];
        if (address && self.addressDetail)
        {
            [detail appendString:address];
            [detail appendString:address.length <= 30 ? @"\n" : @"  "];
        }
        if (location[@"distance"] && self.distanceDetail)
        {
            [detail appendFormat:@"%d", [location[@"distance"] intValue]];
            [detail appendString:NSLocalizedString(@" m", @"Meter unit symbol")];
        }
        cell.detailTextLabel.text = detail.copy;
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.minimumScaleFactor = FSNVHDefaultMinimumScaleFactor;
        cell.detailTextLabel.textColor = self.detailLabelColor;
        
        [cell.imageView.subviews.firstObject removeFromSuperview];
        cell.imageView.image = nil;
        
        if (self.categoryImage)
        {
            NSDictionary *primary = [self primaryCategory:venue];
            
            if (primary)
            {
                [self tableView:tableView setImageForCell:cell withCategory:primary];
            }
        }
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
        NSString *urlString = [NSString stringWithFormat:@"%@%lu%@", category[@"icon"][@"prefix"], (unsigned long)self.imageSize, category[@"icon"][@"suffix"]];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        if (url)
        {
            UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            activityIndicatorView.color = tableView.tintColor;
            
            UIGraphicsBeginImageContext(activityIndicatorView.frame.size);
            
            [UIImage.new drawInRect:CGRectMake(0.0f, 0.0f, activityIndicatorView.frame.size.width, activityIndicatorView.frame.size.height)];
            UIImage *spacer = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            cell.imageView.image = spacer;
            [cell.imageView addSubview:activityIndicatorView];
            [activityIndicatorView startAnimating];
            
            [self downloadAndCacheImage:identifier fromURL:url completion:^{
                NSIndexPath *indexPath = [tableView indexPathForCell:cell];
                if (indexPath)
                {
                    [activityIndicatorView removeFromSuperview];
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
            
            if (completion)
            {
                [NSOperationQueue.mainQueue addOperationWithBlock:^{
                    completion();
                }];
            }
        }
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.selectHandler && self.venues.count > indexPath.row)
    {
        NSDictionary *venue = self.venues[indexPath.row];
        NSDictionary *primary = [self primaryCategory:venue];
        
        NSString *identifier = primary[@"id"];
        UIImage *image = self.cachedImages[identifier];
        
        self.selectHandler(venue, image);
    }
}

@end
