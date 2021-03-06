//
//  ECSUserManager.h
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/** 
 Manages the current authenticated state of the user in the system.
 */
@interface ECSUserManager : NSObject

// The current user token
@property (strong, nonatomic) NSString *userToken;

// The current intent of the user (i.e., mutual funds)
@property (strong, nonatomic) NSString *userIntent;

// The current generated device id
@property (readonly, nonatomic) NSString *deviceID;

@property (strong, nonatomic) NSString *userDisplayName;

@property (strong, nonatomic) UIImage *userAvatar;

// Returns if the user is currently authenticated
@property (readonly, nonatomic, getter=isUserAuthenticated) BOOL userAuthenticated;

/**
 Unauthenticate the current user and log out.
 */
- (void)unauthenticateUser;

@end
