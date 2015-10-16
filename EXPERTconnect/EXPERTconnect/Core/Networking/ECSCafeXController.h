//
//  ECSCafeXController.h
//  EXPERTconnect
//
//  Created by Nathan Keeney on 8/12/15.
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//
#ifndef __LP64__
#import <ACBClientSDK/ACBUC.h>
#import <AssistSDK.h>
#endif

#import "ReachabilityManager.h"
#import "ECSCafeXVideoViewController.h"
#import "ECSRootViewController.h"

// *********************************************
// TODO: Pull out all #ifdef __LP64__ references after CafeX supports 64bit simulators!!
// mas - 15-oct-2015
// *********************************************

#ifdef __LP64__
@interface ECSCafeXController : NSObject <ReachabilityManagerListener, CafeXVideoViewDelegate> {
    
    id cafeXConnection;
#else
@interface ECSCafeXController : NSObject <ACBUCDelegate, ACBClientCallDelegate, ACBClientPhoneDelegate, ReachabilityManagerListener, CafeXVideoViewDelegate> {

    ACBUC *cafeXConnection;
#endif
    
    NSString *username;
    NSString *configuration; // Session ID
    NSString *server; // TODO: Store somewhere
    NSString *port; // TODO: Store somewhere
}

@property (retain) ReachabilityManager *reachabilityManager;
@property (strong, nonatomic) ECSCafeXVideoViewController *cafeXVideoViewController;
@property (copy) void (^postLoginTask)(void);
@property (strong, nonatomic) ECSRootViewController *defaultParent;
    
#ifndef __LP64__
@property (weak, nonatomic) ACBClientCall *savedCall;
#endif 
    
@property (strong, nonatomic) NSString *savedTarget;
@property (nonatomic, assign) BOOL savedVidOption;
@property (nonatomic, assign) BOOL savedAudOption;

- (void)setDefaultParent:(ECSRootViewController *)parent;
- (BOOL)hasCafeXSession;
- (NSString *) cafeXUsername;
- (void)setupCafeXSession;
- (void)setupCafeXSessionWithTask:(void (^)(void))task;
- (void)endCafeXSession;
- (void)dial:(NSString *)target withVideo:(BOOL)vid andAudio:(BOOL)aud usingParentViewController:(ECSRootViewController *)parent;
- (void)startCoBrowse:(NSString *)target usingParentViewController:(ECSRootViewController *)parent;
- (void)endCoBrowse;

+ (void)requestCameraAccess;

@end
