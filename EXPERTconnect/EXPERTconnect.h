//
//  EXPERTconnect.h
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

// Model Imports
#import <EXPERTconnect/ECSJSONObject.h>
#import <EXPERTconnect/ECSActionType.h>
#import <EXPERTconnect/ECSAnswerEngineActionType.h>
#import <EXPERTconnect/ECSAnswerEngineResponse.h>
#import <EXPERTconnect/ECSAnswerEngineRateResponse.h>
#import <EXPERTconnect/ECSAnswerEngineTopQuestionsResponse.h>
#import <EXPERTconnect/ECSCallbackActionType.h>
#import <EXPERTconnect/ECSChatActionType.h>
#import <EXPERTconnect/ECSVideoChatActionType.h>
#import <EXPERTconnect/ECSMessageActionType.h>
#import <EXPERTconnect/ECSSMSActionType.h>
#import <EXPERTconnect/ECSWebActionType.h>
#import <EXPERTconnect/ECSStartJourneyResponse.h>

// Form Imports
#import <EXPERTconnect/ECSFormViewController.h>
#import <EXPERTconnect/ECSFormActionType.h>
#import <EXPERTconnect/ECSForm.h>
#import <EXPERTconnect/ECSFormItem.h>
#import <EXPERTconnect/ECSFormSubmitResponse.h>
#import <EXPERTconnect/ECSFormItemTextArea.h>
#import <EXPERTconnect/ECSFormItemRating.h>
#import <EXPERTconnect/ECSFormItemText.h>
#import <EXPERTconnect/ECSFormItemCheckbox.h>
#import <EXPERTconnect/ECSFormItemRadio.h>
#import <EXPERTconnect/ECSFormItemSlider.h>

#import <EXPERTconnect/ECSSkillDetail.h>
#import <EXPERTconnect/ECSExpertDetail.h>

#import <EXPERTconnect/ECSJSONSerializer.h>
#import <EXPERTconnect/ECSNavigationActionType.h>
#import <EXPERTconnect/ECSNavigationContext.h>
#import <EXPERTconnect/ECSNavigationSection.h>

// UI Imports
#import <EXPERTconnect/ECSCachingImageView.h>
#import <EXPERTconnect/ECSCircleImageView.h>
#import <EXPERTconnect/ECSDynamicViewController.h>
#import <EXPERTconnect/ECSFeaturedTableViewCell.h>
#import <EXPERTconnect/ECSRootViewController.h>
#import <EXPERTconnect/ECSRootViewController+Navigation.h>
#import <EXPERTconnect/ECSWebViewController.h>
#import <ExPERTconnect/ECSChatViewController.h>

#import  "EXPERTconnect/ECSRatingView.h"
//#import <EXPERTconnect/ECSBinaryRating.h>
//#import <EXPERTconnect/ECSBinaryImageView.h>
//#import <EXPERTconnect/ECSCalendar.h>
//#import <EXPERTconnect/ECSRichTextEditor.h>

// Core Networking

#import <EXPERTconnect/ECSStompClient.h>
#import <EXPERTconnect/ECSStompChatClient.h>
#import <EXPERTconnect/ECSStompCallbackClient.h>
#import <EXPERTconnect/ECSChannelStateMessage.h>
#import <EXPERTconnect/ECSChatMessage.h>
#import <EXPERTconnect/ECSChatStateMessage.h>
#import <EXPERTconnect/ECSAddressableChatMessage.h>
#import <EXPERTconnect/ECSChatVoiceAuthenticationMessage.h>

#import <EXPERTconnect/ECSChatAddParticipantMessage.h>
#import <EXPERTconnect/ECSChatRemoveParticipantMessage.h>
#import <EXPERTconnect/ECSSendQuestionMessage.h>
#import <EXPERTconnect/ECSChatNotificationMessage.h>
#import <EXPERTconnect/ECSChatAddChannelMessage.h>
#import <EXPERTconnect/ECSChatAssociateInfoMessage.h>
#import <EXPERTconnect/ECSChatURLMessage.h>

#import <EXPERTconnect/ECSInjector.h>
#import <EXPERTconnect/ECSChatTextMessage.h>
#import <EXPERTconnect/ECSConversationCreateResponse.h>
#import <EXPERTconnect/ECSJourneyAttachResponse.h>
#import <EXPERTconnect/ECSConversationLink.h>
#import <EXPERTconnect/ECSChannelConfiguration.h>
#import <EXPERTconnect/ECSChannelCreateResponse.h>


// #import <EXPERTconnect/ECSRatingView.h>     // kdw: causes "Include of non-modular header inside framework module EXPERTconnect.ECSRatingView"
#import <EXPERTconnect/UIView+ECSNibLoading.h>
#import <EXPERTconnect/ECSViewControllerStack.h>
#import <EXPERTconnect/ECSAnswerRatingView.h>

#import <EXPERTconnect/ECSButton.h>
#import <EXPERTconnect/ECSDynamicLabel.h>
#import <EXPERTconnect/ECSFormTextField.h>
#import <EXPERTconnect/ECSLoadingView.h>
#import <EXPERTconnect/ECSSectionHeader.h>
#import <EXPERTconnect/ECSTheme.h>
#import <EXPERTconnect/ECSUserProfile.h>

#import <EXPERTconnect/ECSJSONSerializing.h>
#import <EXPERTconnect/ECSNotifications.h>
#import <EXPERTconnect/ECSErrorDefinitions.h>
#import <EXPERTconnect/ECSConfiguration.h>
#import <EXPERTconnect/ECSLog.h>

#import <EXPERTconnect/ECSLocalization.h>
#import <EXPERTconnect/ECSURLSessionManager.h>

#import <EXPERTconnect/ECSWorkflow.h>
#import <EXPERTconnect/ECSWorkflowNavigation.h>
#import <EXPERTconnect/ECSMediaInfoHelpers.h>
#import <EXPERTconnect/ECSAuthenticationToken.h>

#import <EXPERTconnect/ECSBreadcrumb.h>
#import <EXPERTconnect/ECSBreadcrumbsSession.h>
#import <EXPERTconnect/ECSBreadcrumbResponse.h>

//! Project version number for EXPERTconnect.
FOUNDATION_EXPORT double EXPERTconnectVersionNumber;

//! Project version string for EXPERTconnect.
FOUNDATION_EXPORT const unsigned char EXPERTconnectVersionString[];

//TODO - This is a temporary flag to stop nullability warnings until we do the work.
#pragma clang diagnostic ignored "-Wnullability-completeness"

#pragma mark -
//Delegate for the Host App to handle events.
@protocol ExpertConnectDelegate <NSObject>

@end

@interface EXPERTconnect : NSObject

@property (strong, nonatomic) ECSTheme                  *theme;
@property (copy, nonatomic) NSString                    *userName;
@property (copy, nonatomic) NSString                    *userIntent;
@property (copy, nonatomic) NSString                    *userDisplayName;
@property (copy, nonatomic) NSString                    *userCallbackNumber;


@property (copy, nonatomic) NSString                    *lastSurveyScore;
@property (copy, nonatomic) NSString                    *surveyFormName;            // Used by the SDK when launching journey-managed forms.
@property (readonly, nonatomic) ECSURLSessionManager    *urlSession;                // Reference to the API wrapper functions

@property (copy, nonatomic) NSString                    *journeyID;
@property (copy, nonatomic) NSString                    *pushNotificationID;
@property (copy, nonatomic) NSString                    *journeyManagerContext;
@property (copy, nonatomic) NSString                    *sessionID;
@property (nonatomic, strong) ECSLog                    *logger;                    // Internal debug logger.

@property (readonly, nonatomic) NSString                *EXPERTconnectVersion;      // SDK version (eg. 6.2.2)
@property (readonly, nonatomic) NSString                *EXPERTconnectBuildVersion; // SDK build version (eg 206)
@property (copy, nonatomic) NSMutableArray              *storedBreadcrumbs;         // When using bulk-send, this is where breadcrumbs are stored.

//@property (readonly, nonatomic) BOOL                  authenticationRequired;
//@property (copy, nonatomic) NSString                  *customerType;
//@property (copy, nonatomic) NSString                  *treatmentType;
//@property (weak) id <ExpertConnectDelegate>           externalDelegate;           // Moxtra

+ (instancetype)shared;

#pragma mark SDK Functions

/**
 Initializes the Humanify SDK components with the given configuration. Refer to Humanify documentation
 to read what the ECSConfiguration object should be populated with.
 */
- (void)initializeWithConfiguration:(ECSConfiguration*)configuration;

/**
 Initializes video components (video chat and co-browse capability). Video module addon required.
 */
//- (void)initializeVideoComponents;

/**
 Returns a view controller for an EXPERTconnect Chat session.
 
 @param chatSkill the Agent Chat Skill for the Chat
 @param displayName for the View Controller
 @param shouldTakeSurvey defunct - no longer used.
 @return the view controller for the Chat
 */
- (UIViewController*)startChat:(NSString*)chatSkill withDisplayName:(NSString*)displayName withSurvey:(BOOL)shouldTakeSurvey;

- (UIViewController*)startChat:(NSString*)chatSkill
               withDisplayName:(NSString*)displayName
                    withSurvey:(BOOL)shouldTakeSurvey
            withChannelOptions:(NSDictionary *)channelOptions;

/**
 Returns a view controller for an EXPERTconnect Chat session, with CafeX Video parameters.
 
 @param chatSkill the Agent Chat Skill for the Chat
 @param displayName for the View Controller
 
 @return the view controller for the Chat
 */
//- (UIViewController*)startVideoChat:(NSString*)chatSkill withDisplayName:(NSString*)displayName;

/**
 Returns a view controller for an EXPERTconnect Chat session, with CafeX Voice parameters.
 
 @param chatSkill the Agent Chat Skill for the Chat
 @param displayName for the View Controller
 
 @return the view controller for the Chat
 */
//- (UIViewController*)startVoiceChat:(NSString*)chatSkill withDisplayName:(NSString*)displayName;

/**
 Returns a view controller for an EXPERTconnect Voice Callback session.
 
 @param chatSkill the Agent Skill for the Callback
 @param displayName for the View Controller
 
 @return the view controller for the Callback
 */
- (UIViewController*)startVoiceCallback:(NSString*)chatSkill withDisplayName:(NSString*)displayName;

/**
 Returns a view controller for an EXPERTconnect Answer Engine session.
 @param aeContext the Answer Engine Context to post the question to
 @return the view controller for the Answer Engine Session
 */
- (UIViewController*)startAnswerEngine:(NSString*)aeContext
                       withDisplayName:(NSString*)displayName;

- (UIViewController*)startAnswerEngine:(NSString *)aeContext
                       withDisplayName:(NSString *)displayName
                         showSearchBar:(BOOL)showSearchBar;

/**
 Returns a view controller for an EXPERTconnect Survey
 @param formName the Name of the Form to launch
 @return the view controller for the Survey
 */
- (UIViewController*)startSurvey:(NSString*)formName;

/**
 Returns a view controller for an EXPERTconnect User Profile Form for the current user
 @return the view controller for the User Profile Controller
 */
- (UIViewController*)startUserProfile;

/**
 Returns a view controller for an EXPERTconnect Email Message
 @return the view controller for the Messaging Controller
 */
//- (UIViewController*)startEmailMessage;

//- (UIViewController*)startEmailMessage:(ECSActionType *)messageAction;

/**
 Returns a view controller for an EXPERTconnect SMS Message
 @return the view controller for the Messaging Controller
 */
//- (UIViewController*)startSMSMessage;

/**
 Returns a view controller for an EXPERTconnect Web Page View
 
 @return the view controller for the Web Page Controller
 */
- (UIViewController*)startWebPage:(NSString *)url;

/**
 Returns a view controller for an EXPERTconnect Answer Engine History View
 
 @return the view controller for the Web Page Controller
 */
- (UIViewController*)startAnswerEngineHistory;

/**
 Returns a view controller for an EXPERTconnect Chat History View
 
 @return the view controller for the Web Page Controller
 */
- (UIViewController*)startChatHistory;

/**
 Returns a view controller for an EXPERTconnect SelectAgent Chat mode
 
 @return the view controller for the Web Page Controller
 */
- (UIViewController*)startSelectExpertChat;
- (UIViewController*)startSelectExpertVideo;
- (UIViewController*)startSelectExpertAndChannel;

/**
 Convenience (wrapper) method for accessing VoiceIt
 
 @param username the Username to attempt to authenticate against.
 @param authCallback a void/String block that handles the callback for a voiceit auth response

 */
//- (void)voiceAuthRequested:(NSString *)username callback:(void (^)(NSString *))authCallback;

/**
 Convenience (wrapper) method for accessing VoiceIt to record a new voice print.
 
 */
//- (void)recordNewEnrollment;

/**
 Convenience (wrapper) method for accessing VoiceIt to clear existing recordings.
 
 */
//- (void)clearEnrollments;

/**
 Logout support. Does not change UI - just removes user token and unauthenticates user.
 
 */
- (void) logout;

/**
 Login support
 @param username the Name of the user attempting to login
 */
- (void) login:(NSString *)username withCompletion:(void (^)(ECSForm *, NSError *))completion;

/**
 Returns a view controller for a specified EXPERTconnect action. If no view controller is
 implemented, then nil is returned.
 
 @param actionType the EXPERTconnect action to get the view controller for.
 
 @return the view controller for the action or nil if no view controller exists to present the 
         action
 */
- (UIViewController*)viewControllerForActionType:(ECSActionType*)actionType;


/**
 Sets a host app delegate to be used for Moxtra event handling. This is TEMPORARY until Moxtra releases an embeddable framework.
 
 @param delegate The ExpertConnectDelegate instance that the host app would like to use to receive Moxtra events.
 */
//- (void)setDelegate:(id)delegate;

/**
 Returns a landing view controller that points to the default view controller for the SDK
 */
//- (UIViewController*)landingViewController;

/**
 *  Starts SDK workflow with a workflowName(workflowID), a delegate, and a viewController to present it on
 */
- (void)startWorkflow:(NSString *)workFlowName
           withAction:(NSString *)actionType
              delgate:(id <ECSWorkflowDelegate>)workflowDelegate
       viewController:(UIViewController *)viewController;

/**
    Starts a workflow but instead of displaying a view controller modally, this will pass it back to display
    in whichever mode the integrator would like.
 */
- (UIViewController *)workflowViewWithAction:(NSString *)actionType
                                    delegate:(id <ECSWorkflowDelegate>)workflowDelegate;

/**
 *  Starts Chat workflow with a workflowName(workflowID), skill name, a delegate, and a viewController to present it on
 */
- (void)startChatWorkflow:(NSString *)workFlowName
                withSkill:(NSString *)skillName
               withSurvey:(BOOL)shouldTakeSurvey
                  delgate:(id <ECSWorkflowDelegate>)workflowDelegate
           viewController:(UIViewController *)viewController;


//- (void) agentAvailabilityWithSkill:(NSString *)skill
//                         completion:(void(^)(NSDictionary *status, NSError *error))completion
//__attribute__((deprecated("Use getDetailsForExpertSkill() instead.")));
//
//- (void) getDetailsForSkill:(NSString *)skill
//                 completion:(void(^)(NSDictionary *details, NSError *error))completion
//__attribute__((deprecated("Use getDetailsForExpertSkill() instead.")));

/**
 Get details for a skill - such as agent availability, etc.
 */
- (void) getDetailsForExpertSkill:(NSString *)skill
                 completion:(void(^)(ECSSkillDetail *details, NSError *error))completion;


/**
 Overwrite the device locale. The format is a locale string (ex: fr_CA)
 */
- (void) overrideDeviceLocale:(NSString *)localeString;
- (NSString *) overrideDeviceLocale;

#pragma mark Journey Functions

/**
 Starts a fresh journey. When a conversation is started, it will use the journeyID fetched by this call if it had
 been invoked beforehand. Otherwise, the conversation begin will fetch a new journeyID. 
 */
- (void) startJourneyWithCompletion:(void (^)(NSString *, NSError *))completion;

/**
@desc Start a journey
@param theName Name of the journey (for reporting, not visible to user) (optional)
@param thePushId An identifier for push notifications (optional)
@param theContext Journey context (optional - default used if missing)
@note (In completion block...)
 NSString journeyID: Identifier of the journey that was just created or fetched
 NSError error:      Error if one occurred. Nil otherwise.
 */
- (void) startJourneyWithName:(NSString *)theName
           pushNotificationId:(NSString *)thePushId
                      context:(NSString *)theContext
                   completion:(void (^)(NSString *, NSError *))completion;

// Set the journey context
- (void) setJourneyContext:(NSString *)theContext
            withCompletion:(void(^)(ECSJourneyAttachResponse *response, NSError *error))completion;

// Send user profile to server.
- (void)setUserProfile:(ECSUserProfile *)userProfile withCompletion:(void (^)(NSDictionary *, NSError *))completion;


/*!
 * @discussion  Directly set the authToken. This method is used if the host app is fetching an authToken from Humanify servers outside of the framework. That token is then plugged into this function call to authenticate any future SDK functions.
 * @param token the identity delegate token
 */
- (void)setUserIdentityToken:(NSString *)token;

/**
 Set the authentication token delegate. This object should contain the function that will refresh
 the token. The EXPERTconnect SDK will call this function if it detects an HTTP 401 (not authorized) error. 
 */
- (void)setAuthenticationTokenDelegate:(id<ECSAuthenticationTokenDelegate>)delegate;

- (void)setUserAvatar:(UIImage *)userAvatar;

/**
 *
 */
-(void)recievedUnrecognizedAction:(NSString *)action;

-(void)setClientID:(NSString *)theClientID
__attribute__((deprecated("See documentation on the Identity Delegate authentication token.")));

-(void)setHost:(NSString *)theHost;


- (void) getTranscriptForConversation:(NSString *)conversationID withCompletion:(void(^)(NSArray *messages, NSError *error))completion;

#pragma mark Breadcrumb Functions

/**
 Send one breadcrumb and allow for a completion handler. The response could potentially include
 further actions for the host app or SDK to take.
 */
- (void) breadcrumbSendOne:(ECSBreadcrumb *)theBreadcrumb
            withCompletion:(void(^)(ECSBreadcrumbResponse *, NSError *))theCompletion;

/**
 Add a breadcrumb to the bulk queue. No completion handler so no synchronous actions can be 
 returned for a bulk breadcrumb. These will send to the server when the cache time or cache count
 is exceeded.
 */
- (void) breadcrumbQueueBulk:(ECSBreadcrumb *)theBreadcrumb;

/**
 Functionally equivalent to "breadcrumbQueueBulk" with different parameters. May be deprecated in the future. 
 Advised to use "breadcrumbQueueBulk" instead. 
 */
- (void) breadcrumbWithAction: (NSString *)actionType
                  description: (NSString *)actionDescription
                       source: (NSString *)actionSource
                  destination: (NSString *)actionDestination
                  geolocation: (CLLocation *)geolocation;

- (void) breadcrumbNewSessionWithCompletion:(void(^)(NSString *, NSError *))completion;

// Dispatch to the server any queued up breadcrumbs. These could be     queued if
// configured to wait a time period or number of breadcrumbs before sending.
- (void) breadcrumbDispatch;

- (void) breadcrumbDispatchWithCompletion:(void(^)(NSDictionary *response, NSError *error))completion;



#pragma mark Utility Functions

/**
 Set the debug level.
 0 - None
 1 - Error
 2 - Warning
 3 - Debug
 4 - Verbose
 */
- (void)setDebugLevel:(int)logLevel;



//Get TimeStamp Meassage
-(NSString *)getTimeStampMessage;

/*
@param callback Block executed when the framework produces a log message.
*/
- (void)setLoggingCallback:(void(^ _Nullable)(ECSLogLevel level, NSString * _Nonnull message))callback;

@end

