//
//  ECSCallbackViewController.h
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ECSRootViewController.h"
#import "ECSStompChatClient.h"
//#import "ECSStompCallbackClient.h"
@class ECSLog;

@interface ECSCallbackViewController : ECSRootViewController <ECSStompChatDelegate>

@property (assign, nonatomic) BOOL      displaySMSOption;
@property (assign, nonatomic) BOOL      skipConfirmationView;
@property (nonatomic, strong) ECSLog    *logger;

@end
