//
//  AppConfig.m
//  EXPERTconnectDemo
//
//  Created by Michael Schmoyer on 2/9/16.
//  Copyright © 2016 Humanify, Inc. All rights reserved.
//

#import "AppConfig.h"

@implementation AppConfig 

#pragma mark Singleton Methods

+ (id)sharedAppConfig {
    static AppConfig *sharedAppConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAppConfig = [[self alloc] init];
    });
    return sharedAppConfig;
}

- (id)init {
    if (self = [super init]) {
        //someProperty = [[NSString alloc] initWithString:@"Default Property Value"];
    }
    return self;
}

#pragma mark Config Functions

-(void) startBreadcrumbSession {
    // Start a new journey, then send an "app launch" breadcrumb.
    
    
    
    [[EXPERTconnect shared] startJourneyWithCompletion:^(NSString *journeyId, NSError *error)
     {
         if( !error )
         {
             NSLog(@"Starting journey with ID=%@", journeyId);
             
             // Send an "app launch" breadcrumb.
             
             [[EXPERTconnect shared] breadcrumbWithAction:@"ECDemo Started"
                                              description:@""
                                                   source:@"ECDemo"
                                              destination:@"Humanify"
                                              geolocation:nil];
         }
     }];
}

// mas - 16-oct-2015 - Fetch available environments and clientID's from a JSON file hosted on our server.
- (void) fetchEnvironmentJSON {
    
    //NSURL *url = [[NSURL alloc] initWithString:@"https://tce1.humanify.com/humanify_sdk_orgs.json"];
    NSURL *url = [[NSURL alloc] initWithString:@"https://dce1.humanify.com/humanify_sdk_orgs.json"];
    
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url]
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         // The server request has completed. Parse file and store it in user defaults.
         if (!error) {
             
             NSError *serializeError;
             NSMutableDictionary *orgDictionary = [NSJSONSerialization
                                                   JSONObjectWithData:data
                                                   options:NSJSONReadingMutableContainers
                                                   error:&serializeError];
             
             //NSLog(@"Env/Org Json: %@", orgDictionary);
             
             if ([orgDictionary objectForKey:@"environment_config"]) {
                 
                 NSDictionary *envConfig = [orgDictionary objectForKey:@"environment_config"];
                 [[NSUserDefaults standardUserDefaults] setObject:envConfig forKey:@"environmentConfig"];
                 
                 //NSLog(@"Saving environment config from JSON successful.");
             }
             
         } else {
             NSLog(@"Error fetching env/org JSON file. Error=%@", error);
         }
     }];
}

// Assigns this object to be the delegate for login retry requests.
-(void) setupAuthenticationDelegate {
    [[EXPERTconnect shared] setAuthenticationTokenDelegate:self];
}

- (NSString *)getHostURL {
    
    NSString *url = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverURL"];
    
    if (!url || url.length == 0)
    {
        url = @"https://api.dce1.humanify.com";
    }
    
    return url;
}

// Attempt to grab organization (clientid) from user defaults. Defaults otherwise.
- (NSString *)getClientID {
    
    NSString *currentOrganization = nil;
    NSString *currentEnv = [[NSUserDefaults standardUserDefaults]
                            objectForKey:@"environmentName"];
    
    if (currentEnv) {
        currentOrganization = [[NSUserDefaults standardUserDefaults]
                               objectForKey:[NSString stringWithFormat:@"%@_%@", currentEnv, @"organization"]];
    }
    
    return ( currentOrganization ? currentOrganization : @"mktwebextc" );
}

-(NSString *)getUserName {
    return ([EXPERTconnect shared].userName ? [EXPERTconnect shared].userName : @"Guest");
}

// This function is called by both this app (host app) and the SDK as the official auth token fetch function.
- (void)fetchAuthenticationToken:(void (^)(NSString *authToken, NSError *error))completion {
    
    // add /ust for new method
    NSURL *url = [[NSURL alloc] initWithString:
                  [NSString stringWithFormat:@"%@/authServerProxy/v1/tokens/ust?username=%@&client_id=%@",
                   [self getHostURL],
                   [self getUserName],
                   [self getClientID]]];
    
    NSLog(@"Fetch token URL: %@", url);
    
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url]
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         
         long statusCode = (long)((NSHTTPURLResponse*)response).statusCode;
         NSString *returnToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         
         if(!error && (statusCode == 200 || statusCode == 201))
         {
             NSLog(@"Successfully fetched authToken: %@", returnToken);
             completion([NSString stringWithFormat:@"%@", returnToken], nil);
         }
         else
         {
             // If the new way didn't work, try the old way once.
             NSLog(@"ERROR FETCHING AUTHENTICATION TOKEN! StatusCode=%ld, Payload=%@", statusCode, returnToken);
             [self fetchOldAuthenticationToken:completion];
         }
     }];
}

// This function is called by both this app (host app) and the SDK as the official auth token fetch function.
- (void)fetchOldAuthenticationToken:(void (^)(NSString *authToken, NSError *error))completion {
    
    // add /ust for new method
    NSURL *url = [[NSURL alloc] initWithString:
                  [NSString stringWithFormat:@"%@/authServerProxy/v1/tokens?username=%@&client_id=%@",
                   [self getHostURL],
                   [self getUserName],
                   [self getClientID]]];
    
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url]
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         
         long statusCode = (long)((NSHTTPURLResponse*)response).statusCode;
         NSString *returnToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         
         if(!error && (statusCode == 200 || statusCode == 201))
         {
             NSLog(@"Successfully fetched authToken: %@", returnToken);
             completion([NSString stringWithFormat:@"%@", returnToken], nil);
         }
         else
         {
             NSLog(@"ERROR FETCHING OLD AUTHENTICATION TOKEN! StatusCode=%ld, Payload=%@", statusCode, returnToken);
             
         }
     }];
}

@end