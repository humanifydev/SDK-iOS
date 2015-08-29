//
//  ECSWorkflow.h
//  EXPERTconnect
//
//  Created by Shammi Didla on 19/08/15.
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECSWorkflowNavigation.h"
#import "ECSRootViewController.h"

@class ECSWorkflow;

@protocol ECSWorkflowNavigationDelegate <NSObject>

- (void)invalidResponseOnAnswerEngineWithCount:(NSInteger)count;

- (void)disconnectedFromVoiceCallBack;
- (void)disconnectedFromChat;
- (void)disconnectedFromVideoChat;

- (void)endWorkFlow;

@end

@protocol ECSWorkflowDelegate <NSObject>

- (NSDictionary *)workflowResponseForWorkflow:(NSString *)workflowName
                               requestCommand:(NSString *)command
                                requestParams:(NSDictionary *)params;

@end

@interface ECSWorkflow : NSObject <ECSWorkflowNavigationDelegate>

@property (nonatomic, copy, readonly) NSString *workflowName;

- (instancetype)initWithWorkflowName:(NSString *)workflowName
                    workflowDelegate:(id <ECSWorkflowDelegate>)workflowDelegate
                   navigationManager:(ECSWorkflowNavigation *)navigationManager;

- (void)start;
- (void)end;

@end
