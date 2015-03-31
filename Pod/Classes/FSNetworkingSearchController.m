//
//  FSNetworkingSearchController.m
//  FSNetworkingSearchController
//
//  Created by alexruperez on 30/3/15.
//
//

#import "FSNetworkingSearchController.h"

#import "FSNetworkingCommunicator.h"


NSString * const FSNSCAccessTokenKey = @"FSNSCAccessToken";
NSString * const FSNSCOAuth2URLString = @"https://foursquare.com/oauth2/";
NSString * const FSNSCVenuesURLString = @"https://api.foursquare.com/v2/venues/";
NSString * const FSNSCAPIVersioning = @"20150401";
NSString * const FSNSCAPIResponse = @"foursquare";
NSString * const FSNSCAPISearchPath = @"search";
NSString * const FSNSCAPISuggestCompletionPath = @"suggestcompletion";

@interface FSNetworkingSearchController () <CLLocationManagerDelegate>
{
    NSString *_accessToken;
}

@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) NSObject<FSNetworkingCommunicatorProtocol> *communicator;

@property (strong, nonatomic) NSString *clientID;
@property (strong, nonatomic) NSString *clientSecret;
@property (strong, nonatomic) NSString *redirectURI;
@property (strong, nonatomic) NSString *accessToken;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) BOOL shouldStopUpdatingLocation;
@property (strong, nonatomic) NSString *suggestPendingQuery;
@property (strong, nonatomic) FSNConnection *suggestCurrentConnection;
@property (strong, nonatomic) NSString *searchPendingQuery;
@property (strong, nonatomic) FSNConnection *searchCurrentConnection;

@property (copy, nonatomic) FSNSCAccessTokenBlock accessTokenCompletion;
@property (copy, nonatomic) FSNSCVenuesBlock suggestCompletion;
@property (copy, nonatomic) FSNSCVenuesBlock searchCompletion;

@end

@implementation FSNetworkingSearchController

- (NSString *)accessToken
{
    if (!_accessToken)
    {
        _accessToken = [self.userDefaults objectForKey:FSNSCAccessTokenKey];
    }
    
    return _accessToken;
}

- (void)setAccessToken:(NSString *)accessToken
{
    if (accessToken && (!_accessToken || ![_accessToken isEqualToString:accessToken]))
    {
        _accessToken = accessToken;
        [self.userDefaults setObject:_accessToken forKey:FSNSCAccessTokenKey];
        [self.userDefaults synchronize];
    }
}

- (NSUserDefaults *)userDefaults
{
    if (!_userDefaults)
    {
        _userDefaults = NSUserDefaults.standardUserDefaults;
    }
    
    return _userDefaults;
}

- (NSObject<FSNetworkingCommunicatorProtocol> *)communicator
{
    if (!_communicator)
    {
        _communicator = FSNetworkingCommunicator.new;
    }
    
    return _communicator;
}

- (CLLocationManager *)locationManager
{
    if (!_locationManager)
    {
        _locationManager = CLLocationManager.new;
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

#pragma mark - Configuration Methods

+ (void)configureWithClientID:(NSString *)clientID clientSecret:(NSString *)clientSecret redirectURI:(NSString *)redirectURI
{
    NSParameterAssert(clientID);
    NSParameterAssert(clientSecret);
    self.sharedController.clientID = clientID;
    self.sharedController.clientSecret = clientSecret;
    self.sharedController.redirectURI = redirectURI;
}

+ (BOOL)isLoggedIn
{
    return self.accessToken;
}

+ (NSString *)accessToken
{
    return self.sharedController.accessToken;
}

+ (void)forceLocation:(CLLocation *)location
{
    self.sharedController.location = location;
}

+ (CLLocation *)currentLocation
{
    if (self.sharedController.location)
    {
        return self.sharedController.location;
    }
    
    if (self.sharedController.locationManager.location)
    {
        return self.sharedController.locationManager.location;
    }
    
    return nil;
}

+ (void)setShouldStopUpdatingLocation:(BOOL)stop
{
    self.sharedController.shouldStopUpdatingLocation = stop;
}

+ (void)setStorage:(NSUserDefaults *)userDefaults
{
    self.sharedController.userDefaults = userDefaults;
}

+ (void)setCommunicator:(NSObject<FSNetworkingCommunicatorProtocol> *)communicator
{
    self.sharedController.communicator = communicator;
}

#pragma mark - Login Methods

+ (void)loginWithCompletion:(FSNSCAccessTokenBlock)completion
{
#if TARGET_OS_IPHONE
    NSParameterAssert(self.sharedController.clientSecret);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@authenticate?client_id=%@&response_type=code&redirect_uri=%@", FSNSCOAuth2URLString, self.sharedController.clientID, self.sharedController.redirectURI]];
    
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        self.sharedController.accessTokenCompletion = completion;
        [[UIApplication sharedApplication] openURL:url];
    }
#endif
}

+ (BOOL)handleOpenURL:(NSURL *)handledURL
{
    NSRange codeRange = [handledURL.absoluteString rangeOfString:@"code="];
    if (codeRange.location != NSNotFound)
    {
        NSUInteger index = codeRange.location + codeRange.length;
        NSString *code = [handledURL.absoluteString substringFromIndex:index];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@access_token?client_id=%@&client_secret=%@&grant_type=authorization_code&redirect_uri=%@&code=%@", FSNSCOAuth2URLString, self.sharedController.clientID, self.sharedController.clientSecret, self.sharedController.redirectURI, code]];
        
        [self.sharedController.communicator startWithUrl:url completionBlock:^(FSNConnection *connection) {
            NSString *accessToken = connection.parseResult[@"access_token"];
            if (accessToken)
            {
                self.sharedController.accessToken = accessToken;
            }
            if (self.sharedController.accessTokenCompletion)
            {
                self.sharedController.accessTokenCompletion(accessToken, connection.error);
            }
        }];
        
        return YES;
    }
    
    return NO;
}

#pragma mark - Search Methods

+ (void)search:(NSString *)searchText completion:(FSNSCVenuesBlock)completion
{
    [self search:searchText intent:nil completion:completion];
}

+ (void)search:(NSString *)searchText intent:(NSString *)intent completion:(FSNSCVenuesBlock)completion
{
    [self search:searchText location:nil intent:intent completion:completion];
}

+ (void)search:(NSString *)searchText location:(CLLocation *)location intent:(NSString *)intent completion:(FSNSCVenuesBlock)completion
{
    [self search:searchText location:location radius:nil intent:intent completion:completion];
}

+ (void)search:(NSString *)searchText location:(CLLocation *)location radius:(NSNumber *)radius intent:(NSString *)intent completion:(FSNSCVenuesBlock)completion
{
    [self search:searchText location:location radius:radius limit:nil intent:intent completion:completion];
}

+ (void)search:(NSString *)searchText location:(CLLocation *)location radius:(NSNumber *)radius limit:(NSNumber *)limit intent:(NSString *)intent completion:(FSNSCVenuesBlock)completion
{
    if (!self.sharedController.clientSecret && !self.sharedController.accessToken)
    {
        [NSException raise:NSStringFromClass(self) format:@"Your need to call first [FSNetworkingSearchController configureWithClientID:YOUR_CLIENT_ID clientSecret:YOUR_CLIENT_SECRET redirectURI:YOUR_REDIRECT_URI];"];
    }
    
    if (searchText.length > 2)
    {
        [self suggestCompletionVenuesForQuery:searchText location:location radius:radius limit:limit completion:completion];
    }
    else if (searchText.length > 0)
    {
        [self searchForQuery:searchText location:location radius:radius limit:limit intent:intent completion:completion];
    }
    else if (completion)
    {
        completion(nil, nil);
    }
}

+ (void)suggestCompletionVenuesForQuery:(NSString *)query completion:(FSNSCVenuesBlock)completion
{
    [self suggestCompletionVenuesForQuery:query location:self.sharedController.location completion:completion];
}

+ (void)suggestCompletionVenuesForQuery:(NSString *)query location:(CLLocation *)location completion:(FSNSCVenuesBlock)completion
{
    [self suggestCompletionVenuesForQuery:query location:location radius:nil completion:completion];
}

+ (void)suggestCompletionVenuesForQuery:(NSString *)query location:(CLLocation *)location radius:(NSNumber *)radius completion:(FSNSCVenuesBlock)completion
{
    [self suggestCompletionVenuesForQuery:query location:location radius:radius limit:nil completion:completion];
}

+ (void)suggestCompletionVenuesForQuery:(NSString *)query location:(CLLocation *)location radius:(NSNumber *)radius limit:(NSNumber *)limit completion:(FSNSCVenuesBlock)completion
{
    NSParameterAssert(query);
    
    self.sharedController.suggestCompletion = completion;
    
    NSMutableString *urlString = [NSMutableString stringWithString:FSNSCVenuesURLString];
    
    [urlString appendString:FSNSCAPISuggestCompletionPath];
    
    [self authorizeMutableURLString:urlString];
    
    if (query)
    {
        [urlString appendFormat:@"&%@=%@", NSStringFromSelector(@selector(query)), query];
    }
    
    if (radius)
    {
        [urlString appendFormat:@"&%@=%d", NSStringFromSelector(@selector(radius)), radius.intValue];
    }
    
    if (limit)
    {
        [urlString appendFormat:@"&%@=%d", NSStringFromSelector(@selector(limit)), limit.intValue];
    }
    
    if (location)
    {
        [urlString appendFormat:@"&ll=%f,%f", location.coordinate.latitude, location.coordinate.longitude];
        
        [self performSuggestCompletionVenuesQuery:urlString.copy];
    }
    else if (self.sharedController.locationManager.location)
    {
        [urlString appendFormat:@"&ll=%f,%f", self.sharedController.locationManager.location.coordinate.latitude, self.sharedController.locationManager.location.coordinate.longitude];
        
        [self performSuggestCompletionVenuesQuery:urlString.copy];
    }
    else
    {
        self.sharedController.suggestPendingQuery = urlString;
        
        [self.sharedController.locationManager startUpdatingLocation];
    }
}

+ (void)searchForQuery:(NSString *)query completion:(FSNSCVenuesBlock)completion
{
    [self searchForQuery:query intent:nil completion:completion];
}

+ (void)searchForQuery:(NSString *)query intent:(NSString *)intent completion:(FSNSCVenuesBlock)completion
{
    [self searchForQuery:query location:self.sharedController.location intent:intent completion:completion];
}

+ (void)searchForQuery:(NSString *)query location:(CLLocation *)location intent:(NSString *)intent completion:(FSNSCVenuesBlock)completion
{
    [self searchForQuery:query location:location radius:nil intent:intent completion:completion];
}

+ (void)searchForQuery:(NSString *)query location:(CLLocation *)location radius:(NSNumber *)radius intent:(NSString *)intent completion:(FSNSCVenuesBlock)completion
{
    [self searchForQuery:query location:location radius:radius limit:nil intent:intent completion:completion];
}

+ (void)searchForQuery:(NSString *)query location:(CLLocation *)location radius:(NSNumber *)radius limit:(NSNumber *)limit intent:(NSString *)intent completion:(FSNSCVenuesBlock)completion
{
    self.sharedController.searchCompletion = completion;
    
    NSMutableString *urlString = [NSMutableString stringWithString:FSNSCVenuesURLString];
    
    [urlString appendString:FSNSCAPISearchPath];
    
    [self authorizeMutableURLString:urlString];
    
    if (query)
    {
        [urlString appendFormat:@"&%@=%@", NSStringFromSelector(@selector(query)), query];
    }
    
    if (radius && (!intent || ![intent isEqualToString:@"match"]))
    {
        [urlString appendFormat:@"&%@=%d", NSStringFromSelector(@selector(radius)), radius.intValue];
        if (!intent || [intent isEqualToString:@"checkin"])
        {
            intent = @"browse";
        }
    }
    
    if (intent)
    {
        [urlString appendFormat:@"&%@=%@", NSStringFromSelector(@selector(intent)), intent];
    }
    
    if (limit)
    {
        [urlString appendFormat:@"&%@=%d", NSStringFromSelector(@selector(limit)), limit.intValue];
    }
    
    if (location)
    {
        [urlString appendFormat:@"&ll=%f,%f", location.coordinate.latitude, location.coordinate.longitude];
        
        [self performSearchQuery:urlString.copy];
    }
    else if (self.sharedController.locationManager.location)
    {
        [urlString appendFormat:@"&ll=%f,%f", self.sharedController.locationManager.location.coordinate.latitude, self.sharedController.locationManager.location.coordinate.longitude];
        
        [self performSearchQuery:urlString.copy];
    }
    else
    {
        self.sharedController.searchPendingQuery = urlString;
        
        [self.sharedController.locationManager startUpdatingLocation];
    }
}

+ (void)cancelPendingConnections
{
    if (self.sharedController.suggestCurrentConnection)
    {
        [self.sharedController.suggestCurrentConnection cancel];
        self.sharedController.suggestCurrentConnection = nil;
        self.sharedController.suggestPendingQuery = nil;
        self.sharedController.suggestCompletion = nil;
    }
    
    if (self.sharedController.searchCurrentConnection)
    {
        [self.sharedController.searchCurrentConnection cancel];
        self.sharedController.searchCurrentConnection = nil;
        self.sharedController.searchPendingQuery = nil;
        self.sharedController.searchCompletion = nil;
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status <= kCLAuthorizationStatusDenied)
    {
        if ([manager respondsToSelector:NSSelectorFromString(@"requestWhenInUseAuthorization")])
        {
            [manager requestWhenInUseAuthorization];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (locations.count)
    {
        CLLocation *location = locations.firstObject;
        if (self.suggestPendingQuery)
        {
            [FSNetworkingSearchController performSuggestCompletionVenuesQuery:[NSString stringWithFormat:@"%@&ll=%f,%f", self.suggestPendingQuery, location.coordinate.latitude, location.coordinate.longitude]];
        }
        
        if (self.searchPendingQuery)
        {
            [FSNetworkingSearchController performSearchQuery:[NSString stringWithFormat:@"%@&ll=%f,%f", self.searchPendingQuery, location.coordinate.latitude, location.coordinate.longitude]];
        }
        
        if (self.shouldStopUpdatingLocation)
        {
            [self.locationManager stopUpdatingLocation];
        }
    }
}

#pragma mark - Private Methods

+ (FSNetworkingSearchController *)sharedController
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = self.new;
    });
    
    return sharedInstance;
}

+ (void)authorizeMutableURLString:(NSMutableString *)urlString
{
    [urlString appendFormat:@"?v=%@", FSNSCAPIVersioning];
    [urlString appendFormat:@"&m=%@", FSNSCAPIResponse];
    
    if (self.isLoggedIn)
    {
        [urlString appendFormat:@"&oauth_token=%@", self.sharedController.accessToken];
    }
    else
    {
        [urlString appendFormat:@"&client_id=%@", self.sharedController.clientID];
        
        [urlString appendFormat:@"&client_secret=%@", self.sharedController.clientSecret];
    }
}

+ (void)performSuggestCompletionVenuesQuery:(NSString *)urlString {
    
    if (self.sharedController.suggestCurrentConnection && !self.sharedController.suggestCurrentConnection.didComplete)
    {
        [self.sharedController.suggestCurrentConnection cancel];
    }
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    self.sharedController.suggestPendingQuery = nil;
    
    self.sharedController.suggestCurrentConnection = [self.sharedController.communicator startWithUrl:url completionBlock:^(FSNConnection *connection) {
        if (self.sharedController.suggestCompletion)
        {
            self.sharedController.suggestCompletion(connection.parseResult[@"response"][@"minivenues"], connection.error);
        }
    }];
}

+ (void)performSearchQuery:(NSString *)urlString {
    
    if (self.sharedController.searchCurrentConnection && !self.sharedController.searchCurrentConnection.didComplete)
    {
        [self.sharedController.searchCurrentConnection cancel];
    }
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    self.sharedController.searchPendingQuery = nil;
    
    self.sharedController.searchCurrentConnection = [self.sharedController.communicator startWithUrl:url completionBlock:^(FSNConnection *connection) {
        if (self.sharedController.searchCompletion)
        {
            self.sharedController.searchCompletion(connection.parseResult[@"response"][@"venues"], connection.error);
        }
    }];
}

@end
