//
//  FSNetworkingViewHandler.h
//  FSNetworkingSearchController
//
//  Created by alexruperez on 30/3/15.
//
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, FSNetworkingImageSize) {
    FSNetworkingImageSize32 = 32,
    FSNetworkingImageSize44 = 44,
    FSNetworkingImageSize64 = 64,
    FSNetworkingImageSize88 = 88
};

typedef void(^FSNSCVenueBlock)(NSDictionary *venue, UIImage *categoryImage);

@interface FSNetworkingViewHandler : NSObject <NSCopying, NSSecureCoding, UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchResultsUpdating>

@property (copy, nonatomic) FSNSCVenueBlock selectHandler;

@property (assign, nonatomic) IBInspectable CGFloat cellHeight;

@property (assign, nonatomic) IBInspectable BOOL refreshControl;

@property (assign, nonatomic) IBInspectable BOOL categoryImage;

@property (assign, nonatomic) IBInspectable BOOL addressDetail;

@property (assign, nonatomic) IBInspectable BOOL distanceDetail;

@property (strong, nonatomic) IBInspectable UIColor *textLabelColor;

@property (strong, nonatomic) IBInspectable UIColor *detailLabelColor;

@property (assign, nonatomic) UIViewContentMode imageContentMode;

@property (assign, nonatomic) FSNetworkingImageSize imageSize;

#pragma mark - Public Methods

- (IBAction)reloadData:(id)sender;

- (void)reloadData:(NSString*)searchText tableView:(UITableView *)tableView completion:(void (^)(void))completion;

@end
