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
@class ECSRootViewController;

@protocol ECSWorkflowNavigationDelegate <NSObject>

- (void)invalidResponseOnAnswerEngineWithCount:(NSInteger)count;
- (void)requestedValidQuestionsOnAnswerEngineCount:(NSInteger)count;
- (void)chatEndedWithTotalInteractionCount:(NSInteger)total
                         agentInteractions:(NSInteger)agentcount
                          userInteractions:(NSInteger)userCount;
- (void)disconnectedFromVoiceCallBack;
- (void)disconnectedFromChat;
- (void)disconnectedFromVideoChat;

- (void)voiceCallBackEnded;

- (void)form:(NSString *)formName submittedWithValue:(NSString *)formValue;

- (void)endWorkFlow;
- (void)minimizeButtonTapped:(id)sender;

- (void)presentVideoChatViewController:(ECSRootViewController *)viewController;
- (void)minimizeVideoButtonTapped:(id)sender;
- (void)endVideoChat;

@end

@protocol ECSWorkflowDelegate <NSObject>

- (void)unrecognizedAction:(NSString *)action;

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
- (void)receivedUnrecognizedAction:(NSString *)action;
@end
