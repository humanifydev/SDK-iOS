//
//  ECSURLSessionManager.h
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ECSAuthenticationToken.h"
#import "ECSBreadcrumb.h"
#import "SessionTaskQueue.h"
#import "ECSMessageTask.h"

@class ECSActionType;

@class ECSAnswerEngineTopQuestionsResponse;
@class ECSAnswerEngineRateResponse;
@class ECSAnswerEngineResponse;
@class ECSCallbackSetupResponse;
@class ECSChatHistoryResponse;
@class ECSConversationCreateResponse;
@class ECSBreadcrumbResponse;
@class ECSStartJourneyResponse;
@class ECSChannelCreateResponse;
@class ECSFormSubmitResponse;
@class ECSHistoryResponse;
@class ECSJourneyAttachResponse;

@class ECSSkillDetail;
@class ECSExpertDetail;
//@class ECSBreadcrumb;

@class ECSChannelConfiguration;
@class ECSForm;
@class ECSHistoryList;
@class ECSNavigationContext;
@class ECSUserProfile;
@class ECSLog;

typedef void (^ECSCodeBlock)(NSString *response, NSError *error);


FOUNDATION_EXPORT NSString *const ECSReachabilityChangedNotification;

typedef NS_ENUM(NSUInteger, ECSHistoryType)
{
    ECSHistoryTypeAll,
    ECSHistoryTypeAnswers,
    ECSHistoryTypeChat
};


/**
 ECSURLSessionManager provides interfaces for performing API calls to the EXPERTconnect servers.
 */

@interface ECSURLSessionManager : NSObject 

@property (nonatomic, strong) SessionTaskQueue *sessionTaskQueue;

// Current host name the API accesses.
@property (nonatomic, strong) NSString *hostName;

@property (nonatomic, readonly) BOOL networkReachable;

@property (nonatomic, assign) BOOL useMessageQueuing;

// Authorization token
@property (nonatomic, strong) NSString *authToken;

@property (nonatomic, weak) id<ECSAuthenticationTokenDelegate> authTokenDelegate;

@property (copy, nonatomic) NSString *journeyID;

@property (nonatomic, strong) NSString *breadcrumbSessionID;

@property (nonatomic, strong) NSString *pushNotificationID;

@property (nonatomic, strong) NSString *journeyManagerContext;

@property (nonatomic, strong) NSString *localLocale;

@property (nonatomic, strong) ECSLog *logger;

@property (nonatomic, strong) NSString *lastChannelId;

// Current conversation
@property (nonatomic, strong) ECSConversationCreateResponse *conversation;

/**
 Returns an instance of the session manager that uses the specified host.
 
 @param host the host to connect to
 
 @return and instance of the object
 */
- (instancetype)initWithHost:(NSString*)host;

/** 
 Performs an OAUTH request to get client credentials for the API
 
 @param clientID the identifier for the client
 @param clientSecret the secret key for the client.
 @param completion the completion block called after authentication is complete.
 
 @return the data task corresponding to this API call
 */
- (NSURLSessionTask *)authenticateAPIWithClientID:(NSString*)clientID
                                        andSecret:(NSString*)clientSecret
                                       completion:(void (^)(NSString *authToken, NSError *error))completion;

/**
 Returns the Decision response JSON for the provided Decision request JSON
 
 @param decisionJson JSON as an NSDictionary
 
 @return the data task corresponding to this API call.
 */
- (NSURLSessionDataTask *)makeDecision:(NSDictionary*)decisionJson
                            completion:(void (^)(NSDictionary *decisionResponse, NSError *error))completion;

/**
 Returns the navigation context with the specified name.  The corresponding data task is returned to
 allow for canceling of the operation.
 
 @param name the name of the navigation content to retrieve
 @param completion called on completion.  Successful responses return the context object and a nil 
                error.  If an error occurs, the error parameter wil be non-nil
 
 @return the data task corresponding to this API call.
 */
- (NSURLSessionDataTask *)getNavigationContextWithName:(NSString*)name
                                            completion:(void (^)(ECSNavigationContext *context, NSError *error))completion;

/**
 Start answer engine journey (0 questions answered) and returns the top questions for given context
 
 @param num the max number of Top Questions to retrieve
 @param context answer engine context
 @param completion block (returns array of questions)
 
 @return the data task for the answer engine call
 */
- (NSURLSessionDataTask *)startAnswerEngineWithTopQuestions:(int)num
                                                 forContext:(NSString*)context
                                             withCompletion:(void (^)(NSArray *questions, NSError *error))completion;

/**
 Returns the top questions for given context
 
 @param num the max number of Top Questions to retrieve
 @param completion block (returns array of questions)
 
 @return the data task for the answer engine call
 */
- (NSURLSessionDataTask *)getAnswerEngineTopQuestions:(int)num
                                       withCompletion:(void (^)(NSArray *questions, NSError *error))completion;

/**
 Returns the top questions for given context
 
 @param num the max number of Top Questions to retrieve
 @param context answer engine context
 @param completion block (returns array of questions)
 
 @return the data task for the answer engine call
 */
- (NSURLSessionDataTask *)getAnswerEngineTopQuestions:(int)num
                                           forContext:(NSString*)context
                                       withCompletion:(void (^)(NSArray *questions, NSError *error))completion;

/**
 Retrieves the top question from answer engine using a search keyword
 
 @param theKeyword The search string to use
 
 @return the data task for the answer engine call
 */
- (NSURLSessionDataTask *)getAnswerEngineTopQuestionsForKeyword:(NSString*)theKeyword
                                            withOptionalContext:(NSString*)theContext
                                                     completion:(void (^)(ECSAnswerEngineResponse *response, NSError *error))completion;

/**
 Asks a question of the answer engine system.
 
 @param question the question to ask
 @param answerEngineContext the context of the answer engine
 @param customData custom data to send with the request
 @param completion completion block called when the request is complete
 
 @return the data task for the answer engine call
 */
- (NSURLSessionDataTask *)getAnswerForQuestion:(NSString*)question
                                     inContext:(NSString*)answerEngineContext
                                    customData:(NSDictionary *)customData
                                    completion:(void (^)(ECSAnswerEngineResponse *response, NSError *error))completion;

/**
 Asks a question of the answer engine system.
 
 @param question the question to ask
 @param answerEngineContext the context of the answer engine
 @param parentNavigator the parent navigation context
 @param actionId the action ID that defined this answer engine context.
 @param questionCount the current number of asked questions
 @param customData custom data to send with the request
 @param completion completion block called when the request is complete
 
 @return the data task for the answer engine call
 */
- (NSURLSessionDataTask *)getAnswerForQuestion:(NSString*)question
                                     inContext:(NSString*)answerEngineContext
                               parentNavigator:(NSString*)parentNavigator
                                      actionId:(NSString*)actionId
                                 questionCount:(NSUInteger)questionCount
                                    customData:(NSDictionary *)customData
                                    completion:(void (^)(ECSAnswerEngineResponse *response, NSError *error))completion;

/**
 Rates a specific answer with the specified id.
 
 @param answerID the identifier of the answer to rate
 @param inquiryID the identifier of the inquiry that returned the answer
 @param rating the rating to send
 @param theMin minimum rating value
 @param theMax maximum rating value
 @param questionCount the current number of asked questions
 @param completion completion block called when the request is complete
 
 @return the data task for the rate answer call
 */
- (NSURLSessionDataTask *)rateAnswerWithAnswerID:(NSString*)answerID
                                       inquiryID:(NSString*)inquiryID
                                          rating:(int)rating
                                             min:(int)theMin
                                             max:(int)theMax
                                   questionCount:(int)questionCount
                                      completion:(void (^)(ECSAnswerEngineRateResponse *response, NSError *error))completion;

// Deprecated Jun-23-2016
- (NSURLSessionDataTask *)getResponseFromEndpoint:(NSString *)endpoint
                                   withCompletion:(void (^)(id, NSError *))completion;
//__attribute__((deprecated("This function will be removed in a later release.")));

- (NSURLSessionDataTask *)getUserProfileWithCompletion:(void (^)(ECSUserProfile *, NSError *))completion;

- (NSURLSessionDataTask *)submitUserProfile:(ECSUserProfile *)profile withCompletion:(void (^)(NSDictionary *, NSError *))completion;

/**
 Get list of experts
 @param theInteractionItems Dictionary of values that may be used to more accurately select experts
 @param completion Completion block (returns object)
 @return the data task for the select experts call
 */
- (NSURLSessionDataTask *)getExpertsWithInteractionItems:(NSDictionary *)theInteractionItems
                                              completion:(void (^)(NSArray *, NSError *))completion;

- (NSURLSessionDataTask *)getFormNamesWithCompletion:(void (^)(NSArray *formNames, NSError *error))completion;

- (NSURLSessionDataTask *)getFormByName:(NSString*)formName withCompletion:(void (^)(ECSForm *form , NSError *error))completion;

/**
 Submits the specified form.
 
 @param form the form to submit
 @param completion completion block called when the request is complete
 
 @return the data task for the rate answer call
 */
- (NSURLSessionDataTask *)submitForm:(ECSForm*)form
                          completion:(void (^)(ECSFormSubmitResponse *response, NSError *error))completion;


- (NSURLSessionDataTask *)submitForm:(ECSForm*)form
                              intent:(NSString*)intent
                   navigationContext:(NSString*)navigationContext
                      withCompletion:(void (^)(ECSFormSubmitResponse *response, NSError *error))completion;

/**
 Login with username / password
 
 @param username The username to log in as
 @param password The password for the user
 @param completion The block to call with the authenticated user information, or an NSError indicating that the
        call has failed.
 @return the data task corresponding to this API call
 */
- (NSURLSessionDataTask*)performLoginWithUsername:(NSString*)username
                                         password:(NSString*)password
                                       completion:(void (^)(id userData, NSError* error))completion;
/**
 Register a user with the provided full name, email, and password.
 
 @param fullName The user's full name to register
 @param email User's email address to register
 @param mobileNumber the user's mobile number to use for registration
 @param completion The block to call when the user is registered, or an NSError indicating that the call has failed.
 @return the data task corresponding to this API call
 */
- (NSURLSessionDataTask*)performRegistrationWithFullName:(NSString*)fullName
                                            emailAddress:(NSString*)email
                                            mobileNumber:(NSString*)mobileNumber
                                              completion:(void (^)(id userData, NSError* error))completion;


#pragma mark - ConversationEngine

- (NSURLSessionTask *)refreshIdentityDelegate:(int)theRetryCount
                               withCompletion:(void (^)(NSString *authToken, NSError *error))completion;

/**
 Starts a new conversation and call the callback once the new conversation is complete.  
 This call also stores the journey ID for future use in other API calls.
 
 @param actionType the action type to use when starting the conversation
 @param alwaysCreate create a conversation if necessary and there is not currently a conversation
                     with a journey.
 @param completion the completion block called after the setup is complete.
 
 @return the data task associated with the conversation
 */
- (NSURLSessionDataTask*)startConversationForAction:(ECSActionType*)actionType
                                    andAlwaysCreate:(BOOL)alwaysCreate
                                     withCompletion:(void (^)(ECSConversationCreateResponse *conversation, NSError *error))completion;

/**
 Sets up a websocket chat conversation at the specified location.
 
 @param location the location to access with the conversation
 @param completion the completion block called when setup is complete.
 
 @return the data task corresponding to this API call
 */
- (NSURLSessionDataTask*)setupConversationWithLocation:(NSString*)location
                                            completion:(void (^)(ECSConversationCreateResponse *createResponse, NSError* error))completion;

/**
 Sets up a websocket chat channel with the specified configuration and conversation.
 
 @param channelConfig the configuration to use when setting up the channel
 @param conversation the conversation to create the channel in
 @param completion the completion block called when setup is complete.
 
 @return the data task corresponding to this API call
 */
- (NSURLSessionDataTask*)setupChannel:(ECSChannelConfiguration*)channelConfig
                       inConversation:(NSString*)conversation
                           completion:(void (^)(ECSChannelCreateResponse *response, NSError* error))completion;

/**
 Closes a channel at the specified URL with a given reason.
 
 @param closeChannelURL the URL to utilize when closing the channel
 @param reason the reason why the channel may have closed
 @param interactionCount the number of agent interactions that have occured
 @param completion the completion block called when setup is complete.
 
 @return the data task corresponding to the API call.
 */
- (NSURLSessionDataTask*)closeChannelAtURL:(NSString*)closeChannelURL
                                withReason:(NSString*)reason
                     agentInteractionCount:(NSInteger)interactionCount
                                  actionId:(NSString*)actionId
                                completion:(void (^)(id result, NSError* error))completion;

/**
 */
- (NSURLSessionDataTask*)getEndChatActionsForConversationId:(NSString*)conversationId
                                  withAgentInteractionCount:(NSInteger)interactionCount
                                          navigationContext:(NSString*)navigationContext
                                                   actionId:(NSString*)actionId
                                                 completion:(void (^)(NSArray *result, NSError* error))completion;


/**
 Send a chat message from the client (REST POST)
 @param messageString The message body
 @param fromString The FROM address
 @param channelString The channelID string to identify which channel to send to.
 @param completion Completion block
 @return (completion block) Response text (not currently used)
 */
- (NSURLSessionDataTask*)sendChatMessage:(NSString *)messageString
                                    from:(NSString *)fromString
                                 channel:(NSString *)channelString
                              completion:(void(^)(NSString *response, NSError *error))completion;


/**
 Send a chat state update from the client (REST POST)
 
 @param theChatState The chat state update message body
 @param theDuration Duration of the particular state
 @param theChannel The channelID string to identify which channel to send to.
 @param completion Completion block
 
 @return (completion block) Response text (not currently used)
 */
- (NSURLSessionDataTask*)sendChatState:(NSString *)theChatState
                              duration:(int)theDuration
                               channel:(NSString *)theChannel
                            completion:(void(^)(NSString *response, NSError *error))completion;

/**
 Send a chat notification update from the client (REST POST)
 
 @param fromString The FROM address
 @param typeString The TYPE of notification message
 @param objectDataString ???
 @param convoIdString The conversationID string to send to.
 @param theChannel The channelID string to identify which channel to send to.
 @param completion Completion block
 
 @return (completion block) Response text (not currently used)
 */
- (NSURLSessionDataTask*)sendChatNotificationFrom:(NSString *)fromString
                                             type:(NSString *)typeString
                                       objectData:(NSString *)objectDataString
                                   conversationId:(NSString *)convoIdString
                                          channel:(NSString *)theChannel
                                       completion:(void(^)(NSString *response, NSError *error))completion;

/**
 Get details on a chat or voice callback channel (such as state=pending)
 
 @param channelString ChannelID string used to identify which channel to return
 @param completion Completion block
 
 @return (completion block) ECSChannelConfiguration object
 */
- (NSURLSessionDataTask*)getDetailsForChannelId:(NSString *)channelString
                                     completion:(void(^)(ECSChannelConfiguration *response, NSError *error))completion;

#pragma mark Agent Availability

// MAS - Old deprecated functions. 
//- (NSURLSessionDataTask*)getDetailsForSkills:(NSArray *)skills completion:(void(^)(NSDictionary *response, NSError *error))completion;
//- (NSURLSessionDataTask*)getDetailsForSkill:(NSString *)skill completion:(void(^)(NSDictionary *response, NSError *error))completion;

/**
 Get details for a particular call or chat skill
 
 @param skill Skill name to return data for (ex. "calls_for_mike")
 @param completion Completion block
 
 @return (completion block) ECSAgentAvailableResponse object
 */
- (NSURLSessionDataTask*)getDetailsForExpertSkill:(NSString *)skill
                                 completion:(void(^)(NSDictionary *response, NSError *error))completion;

/**
 Get details for a particular call or chat skill
 
 @param skills Skill name to return data for (ex. "calls_for_mike")
 @param completion Completion block
 
 @return (completion block) ECSAgentAvailableResponse object
 */
- (NSURLSessionDataTask*)getDetailsForExpertSkills:(NSArray *)skills
                                       completion:(void(^)(NSDictionary *response, NSError *error))completion;

/*!
 * @discussion Validate that network connectivity to the API is successful and the API server is healthy (returns successful packet)
 * @param completion One parameter - "success" when API connection is successful.
 */
- (void)validateAPI:(void(^)(bool success))completion;

#pragma mark Journey Management

// Start a new journey
- (NSURLSessionDataTask*)setupJourneyWithCompletion:(void (^)(ECSStartJourneyResponse *response, NSError* error))completion;

- (NSURLSessionDataTask*)setupJourneyWithName:(NSString *)theName
                           pushNotificationId:(NSString *)thePushId
                                      context:(NSString *)theContext
                                   completion:(void (^)(ECSStartJourneyResponse *response, NSError* error))completion;

- (NSURLSessionDataTask*)setJourneyContext:(NSString*)context
                                completion:(void (^)(ECSJourneyAttachResponse *response, NSError* error))completion;


#pragma mark - Media upload
/**
 Uploads the specified data block as a file using a multipart/form upload.
 
 @param data the file data to upload
 @param name the name of the file to upload
 @param fileContentType the MIME content type of the file
 @param completion the completion block called when the upload is complete
 
 @return the upload task corresponding to the network call
 */
- (NSURLSessionUploadTask*)uploadFileData:(NSData*)data
                                 withName:(NSString*)name
                          fileContentType:(NSString*)fileContentType
                               completion:(void (^)(id *response, NSError* error))completion;

- (NSURLRequest*)urlRequestForMediaWithName:(NSString*)name;

- (NSURLSessionDataTask *)getMediaFileNamesWithCompletion:(void (^)(NSArray *, NSError *))completion;

#pragma mark - History
/**
 Gets the conversation history with the specified type.
 
 @param completion the completion block called when the network call is complete.
 
 @return the data task corresponding to this API call
 */
- (NSURLSessionDataTask*)getAnswerEngineHistoryWithCompletion:(void (^)(ECSHistoryList *response, NSError* error))completion;

- (NSURLSessionDataTask*)getChatHistoryWithCompletion:(void (^)(ECSHistoryList *response, NSError* error))completion;

- (NSURLSessionDataTask*)getChatHistoryDetailsForJourneyId:(NSString*)journeyId
                                            withCompletion:(void (^)(ECSChatHistoryResponse *response, NSError* error))completion;

#pragma mark - Utilities

- (id)getClassOfType:(Class)aClass withJSON:(id)result;

- (NSURLSessionDataTask *)externalRequestWithMethod:(NSString *)method
                                               path:(NSString *)path
                                         parameters:(id)parameters
                                            success:(void(^)(id result, NSURLResponse *response))success
                                            failure:(void(^)(id result, NSURLResponse *response, NSError *error))failure;

/* NO JSON SERIALIZATION! */
- (NSURLSessionDataTask *)externalStringRequestWithMethod:(NSString *)method
                                               path:(NSString *)path
                                         parameters:(id)parameters
                                            success:(void(^)(NSURLResponse *response, NSString *data))success
                                            failure:(void(^)(NSURLResponse *response, NSError *error))failure;


//- (NSString *) getJourneyID ;
- (NSString *) getConversationID ;

#pragma mark Breadcrumbs

- (NSURLSessionDataTask *)breadcrumbActionSingle:(id)actionJson
                                      completion:(void (^)(ECSBreadcrumbResponse *json, NSError *error))completion;

- (NSURLSessionDataTask *)breadcrumbsAction:(id)actionJson
                                 completion:(void (^)(NSDictionary *decisionResponse, NSError *error))completion;

- (NSURLSessionDataTask *)breadcrumbsSession:(id)actionJson
                                  completion:(void (^)(NSDictionary *decisionResponse, NSError *error))completion;

@end
