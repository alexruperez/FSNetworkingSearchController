//
//  FSNetworkingSearchController.h
//  FSNetworkingSearchController
//
//  Created by alexruperez on 30/3/15.
//
//

#import <CoreLocation/CoreLocation.h>
#import <FSNetworking/FSNConnection.h>

#if TARGET_OS_IPHONE
#import "FSNetworkingViewHandler.h"
#endif


typedef void(^FSNSCVenuesBlock)(NSArray *venues, NSError *error);
typedef void(^FSNSCAccessTokenBlock)(NSString *accessToken, NSError *error);

@protocol FSNetworkingCommunicatorProtocol <NSObject>

- (FSNConnection *)startWithUrl:(NSURL *)url completionBlock:(FSNCompletionBlock)completionBlock;

- (FSNConnection *)startWithUrl:(NSURL *)url method:(FSNRequestMethod)method headers:(NSDictionary*)headers parameters:(NSDictionary*)parameters parseBlock:(FSNParseBlock)parseBlock completionBlock:(FSNCompletionBlock)completionBlock progressBlock:(FSNProgressBlock)progressBlock;

@end

@interface FSNetworkingSearchController : NSObject

#pragma mark - Configuration Methods

+ (void)configureWithClientID:(NSString *)clientID clientSecret:(NSString *)clientSecret redirectURI:(NSString *)redirectURI;

+ (BOOL)isLoggedIn;

+ (NSString *)accessToken;

+ (void)forceLocation:(CLLocation *)location;

+ (CLLocation *)currentLocation;

+ (void)setShouldStopUpdatingLocation:(BOOL)stop;

+ (void)setStorage:(NSUserDefaults *)userDefaults;

+ (void)setCommunicator:(NSObject<FSNetworkingCommunicatorProtocol> *)communicator;

#pragma mark - Login Methods

+ (void)loginWithCompletion:(FSNSCAccessTokenBlock)completion;

+ (BOOL)handleOpenURL:(NSURL *)handledURL;

#pragma mark - Search Methods

+ (void)search:(NSString *)searchText completion:(FSNSCVenuesBlock)completion;

+ (void)search:(NSString *)searchText location:(CLLocation *)location radius:(NSNumber *)radius limit:(NSNumber *)limit intent:(NSString *)intent completion:(FSNSCVenuesBlock)completion;

+ (void)cancelPendingConnections;

@end
