//
//  EXPERTconnect.m
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import "EXPERTconnect.h"

//#import "ECSCafeXController.h"
//#import "ECSVoiceItManager.h"

#import "ECSURLSessionManager.h"
#import "ECSImageCache.h"
#import "ECSInjector.h"
#import "ECSTheme.h"
#import "ECSUserManager.h"
#import "ECSLocalization.h"

#import "NSBundle+ECSBundle.h"
#import "UIViewController+ECSNibLoading.h"
#import "ECSAnswerEngineViewController.h"   // TODO: Eliminate references to "specific" View Controllers!

#import "ECSWorkflowNavigation.h"
@class ECSLog;

@interface EXPERTconnect ()
@property (nonatomic, strong) ECSWorkflow *workflow;

@end

static EXPERTconnect* _sharedInstance;

//NSMutableArray *storedBreadcrumbs;
NSTimer *breadcrumbTimer;

@implementation EXPERTconnect

@synthesize storedBreadcrumbs;

+ (instancetype)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [EXPERTconnect new];
    });
    
    return _sharedInstance;
}


- (instancetype)init
{
    if((self = [super init]))
    {
        _logger = [[ECSLog alloc] init];

    }
    return self;
}
#pragma mark Initialization Functions

/**
 @desc Initialize the SDK with provided configuration object
 @param configuration An SDK configuration object. At minimum, the host parameter is required to be populated.
 */
- (void)initializeWithConfiguration:(ECSConfiguration*)configuration
{
    NSAssert(configuration.host, @"You must specify the host when initializing the EXPERTconnect SDK.");
    
    // Log config for debugging (at level: error, which means debugLevel 1 or higher)
    ECSLogError(self.logger,@"Initialized SDK with configuration:\nhost: %@\ncafeXHost: %@\nappName: %@ %@ (appId: %@)\ndefaultNavigationContext: %@", configuration.host, configuration.cafeXHost, configuration.appName, configuration.appVersion, configuration.appId, configuration.defaultNavigationContext);
    
    ECSURLSessionManager* sessionManager = [[ECSURLSessionManager alloc] initWithHost:configuration.host];
    [[ECSInjector defaultInjector] setObject:configuration forClass:[ECSConfiguration class]];
    [[ECSInjector defaultInjector] setObject:sessionManager
                                    forClass:[ECSURLSessionManager class]];
    [[ECSInjector defaultInjector] setObject:[ECSImageCache new] forClass:[ECSImageCache class]];
    [[ECSInjector defaultInjector] setObject:[ECSTheme new] forClass:[ECSTheme class]];
    [[ECSInjector defaultInjector] setObject:[ECSUserManager new] forClass:[ECSUserManager class]];
//    [[ECSInjector defaultInjector] setObject:[ECSVoiceItManager new] forClass:[ECSVoiceItManager class]];

    //[self initializeVideoComponents];

    _userCallbackNumber = nil;
}

//- (void)initializeVideoComponents
//{
//    ECSCafeXController *cafeXController = [[ECSInjector defaultInjector] objectForClass:[ECSCafeXController class]];
//
//    // Do a login if there's no session:
//    if (![cafeXController hasCafeXSession]) {
//        [cafeXController setupCafeXSession];
//    }
//}

#pragma mark Properties

// Unit Test: EXPERTconnectTests::testProperties
//- (BOOL)authenticationRequired
//{
//    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
//    return ![userManager isUserAuthenticated];
//}

- (ECSTheme *)theme
{
    return [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
}

- (void)setTheme:(ECSTheme *)theme
{
    [[ECSInjector defaultInjector] setObject:theme forClass:[ECSTheme class]];
}

-(NSString *)host
{
    ECSConfiguration *configuration = [[ECSInjector defaultInjector] objectForClass:[ECSConfiguration class]];
    return configuration.host;
}
-(void)setHost:(NSString *)theHost
{
    ECSConfiguration *configuration = [[ECSInjector defaultInjector] objectForClass:[ECSConfiguration class]];
    configuration.host = theHost;
    
    // Set the host in the session manager.
    ECSURLSessionManager *sessionManager = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
    [sessionManager setHostName:theHost];
    //sessionManager.conversation = nil;
}

-(NSString *)clientID
{
    ECSConfiguration *configuration = [[ECSInjector defaultInjector] objectForClass:[ECSConfiguration class]];
    return configuration.clientID;
}

-(void)setClientID:(NSString *)theClientID
{
    ECSConfiguration *configuration = [[ECSInjector defaultInjector] objectForClass:[ECSConfiguration class]];
    configuration.clientID = theClientID;
    
    // Reset the auth token. This should make us fetch a new one.
    ECSURLSessionManager *sessionManager = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
    sessionManager.authToken = nil;
    //sessionManager.conversation = nil;
    [self setSessionID:nil]; // Clear the breadcrumb token.
}

- (void)setUserIntent:(NSString *)intent
{
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    userManager.userIntent = intent;
}

- (void)setUserAvatar:(UIImage *)userAvatar
{
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    userManager.userAvatar = userAvatar;
}

// Unit Test: EXPERTconnectTests::testProperties
- (NSString *)userIntent
{
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    return userManager.userIntent;
}

- (ECSURLSessionManager *)urlSession
{
    return [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
}

// Unit Test: EXPERTconnectTests::testProperties
- (NSString *)userName
{
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    return userManager.userToken;
}

- (void)setUserName:(NSString *)userName
{
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    userManager.userToken = userName;
    
    if (!userName || (userName.length == 0))
    {
        [userManager unauthenticateUser];
    }
    else
    {
        // Send a profile with just username.
        ECSUserProfile * profile = [ECSUserProfile new];
        profile.username = userManager.userToken;
        [self setUserProfile:profile withCompletion:nil];
    }
}

// Send user profile to server.
- (void)setUserProfile:(ECSUserProfile *)userProfile withCompletion:(void (^)(NSDictionary *, NSError *))completion
{
    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    [sessionManager submitUserProfile:userProfile withCompletion:completion];
}

// Directly set the authToken

- (void)setUserIdentityToken:(NSString *)token
{
    ECSURLSessionManager *sessionManager = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
    sessionManager.authToken = token;
}

/**
 @desc Sets the user identity token delegate function. This function is used by the SDK to re-authenticate if an authentication token expires or fails authentication. If a function is provided here, the SDK will automatically try to fetch a new token. 
 @param delegate The delegate function. See definition of ECSAuthenticationTokenDelegate for details.
 */
- (void)setAuthenticationTokenDelegate:(id<ECSAuthenticationTokenDelegate>)delegate
{
    ECSURLSessionManager *sessionManager = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
    sessionManager.authTokenDelegate = delegate;
}

// Unit Test: EXPERTconnectTests::testProperties
- (NSString *)userDisplayName
{
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    return userManager.userDisplayName;
}

- (void)setUserDisplayName:(NSString *)userDisplayName
{
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    userManager.userDisplayName = userDisplayName;
}

// Unit Test: EXPERTconnectTests::testProperties
- (NSString*)EXPERTconnectVersion
{
    return [NSBundle ecs_bundleVersion];
}

// Unit Test: EXPERTconnectTests::testProperties
- (NSString*)EXPERTconnectBuildVersion
{
    return [NSBundle ecs_buildVersion];
}

// Unit Test: EXPERTconnectTests::testProperties
-(NSString *)journeyID {
    return self.urlSession.journeyID;
}
-(void)setJourneyID:(NSString *)theJourneyID {
    self.urlSession.journeyID = theJourneyID;
}

// Unit Test: EXPERTconnectTests::testProperties
-(NSString *)journeyManagerContext {
    return self.urlSession.journeyManagerContext;
}
-(void)setJourneyManagerContext:(NSString *)theContext {
    self.urlSession.journeyManagerContext = theContext;
}

// Unit Test: EXPERTconnectTests::testProperties
-(NSString *)pushNotificationID {
    return self.urlSession.pushNotificationID;
}
-(void)setPushNotificationID:(NSString *)thePushNotificationID {
    self.urlSession.pushNotificationID = thePushNotificationID;
}

/**
 Set the debug level.
 0 - None
 1 - Error
 2 - Warning
 3 - Debug
 4 - Verbose
 */
- (void)setDebugLevel:(int)logLevel {
    if(logLevel>0)NSLog(@"EXPERTconnect SDK: Debug level set to %d", logLevel);
    ECSLogSetLogLevel(logLevel);
}

// Unit Test: EXPERTconnectTests::testProperties
-(NSString *)getTimeStampMessage
{
    // get current date/time
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // display in 12HR/24HR (i.e. 11:25PM or 23:25) format according to User Settings
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    
    return currentTime;
}

/**
 Set the header for locale when sending to the Humanify server. Does not override localization strings.
 */
- (void) overrideDeviceLocale:(NSString *)localeString
{
    self.urlSession.localLocale = localeString;
}

// Unit Test: EXPERTconnectTests::testProperties
- (NSString *) overrideDeviceLocale
{
    return self.urlSession.localLocale;
}

- (UIViewController *)viewControllerForActionType:(ECSActionType *)actionType
{
    return [ECSRootViewController ecs_viewControllerForActionType:actionType];
}

//- (void)setDelegate:(id)delegate {
//    _externalDelegate = delegate;
//}

- (UIViewController*)landingViewController
{
    ECSConfiguration *configuration = [[ECSInjector defaultInjector] objectForClass:[ECSConfiguration class]];
    ECSNavigationActionType *navigationAction = [ECSNavigationActionType new];
    navigationAction.displayName = configuration.defaultNavigationDisplayName;
    navigationAction.navigationContext = configuration.defaultNavigationContext;
    
    return [ECSRootViewController ecs_viewControllerForActionType:navigationAction];
}

#pragma mark High Level UI Function Calls

- (UIViewController*)startChat:(NSString*)chatSkill
               withDisplayName:(NSString*)displayName
                    withSurvey:(BOOL)shouldTakeSurvey
{
    // Call newer function to prevent code duplication. 
    return [self startChat:chatSkill
           withDisplayName:displayName
                withSurvey:shouldTakeSurvey
        withChannelOptions:nil];
}

- (UIViewController*)startChat:(NSString*)chatSkill
               withDisplayName:(NSString*)displayName
                    withSurvey:(BOOL)shouldTakeSurvey
            withChannelOptions:(NSDictionary *)channelOptions
{
    // Nathan Keeney 9/1/2015 changed to ALLOW CafeX escalation (no change to vanilla chats):
    ECSVideoChatActionType *chatAction = [ECSVideoChatActionType new];
    chatAction.actionId = @"";
    chatAction.agentSkill = chatSkill;
    chatAction.displayName = displayName;
    chatAction.shouldTakeSurvey = shouldTakeSurvey;
    //chatAction.journeybegin = [NSNumber numberWithInt:1];
    
    if (channelOptions) {
        chatAction.channelOptions = [NSDictionary dictionaryWithDictionary:channelOptions];
    }
    
    [self breadcrumbDispatchWithCompletion:nil];
    
//    ECSCafeXController *cafeXController = [[ECSInjector defaultInjector] objectForClass:[ECSCafeXController class]];
//    // Do a login if there's no session:
//    if (![cafeXController hasCafeXSession]) {
//        [cafeXController setupCafeXSession];
//    }
//    chatAction.cafexmode = @"videocapable,voicecapable,cobrowsecapable";
//    chatAction.cafextarget = [cafeXController cafeXUsername];
    
    UIViewController *chatController = [self viewControllerForActionType:chatAction];
    
    return chatController;
}

- (UIViewController*)startVideoChat:(NSString*)chatSkill withDisplayName:(NSString*)displayName
{
//    ECSCafeXController *cafeXController = [[ECSInjector defaultInjector] objectForClass:[ECSCafeXController class]];
//
//    // Do a login if there's no session:
//    if (![cafeXController hasCafeXSession]) {
//        [cafeXController setupCafeXSession];
//    }
    
    ECSVideoChatActionType *chatAction = [ECSVideoChatActionType new];
    chatAction.actionId = @"";
    chatAction.agentSkill = chatSkill;
    chatAction.displayName = displayName;
    chatAction.cafexmode = @"videoauto";
//    chatAction.cafextarget = [cafeXController cafeXUsername];
    
    UIViewController *chatController = [self viewControllerForActionType:chatAction];
    
    return chatController;
}

//- (UIViewController*)startVoiceChat:(NSString*)chatSkill withDisplayName:(NSString*)displayName {
//
//    ECSCafeXController *cafeXController = [[ECSInjector defaultInjector] objectForClass:[ECSCafeXController class]];
//
//    // Do a login if there's no session:
//    if (![cafeXController hasCafeXSession]) {
//        [cafeXController setupCafeXSession];
//    }
//
//    ECSVideoChatActionType *chatAction = [ECSVideoChatActionType new];
//    chatAction.actionId = @"";
//    chatAction.agentSkill = chatSkill;
//    chatAction.displayName = displayName;
//    chatAction.cafexmode = @"voiceauto";
//    chatAction.cafextarget = [cafeXController cafeXUsername];
//
//    UIViewController *chatController = [self viewControllerForActionType:chatAction];
//
//    return chatController;
//}

- (UIViewController*)startVoiceCallback:(NSString*)callSkill withDisplayName:(NSString*)displayName {
    
    ECSCallbackActionType *cbAction = [ECSCallbackActionType new];
    cbAction.actionId               = @"";
    cbAction.agentSkill             = callSkill;
    cbAction.displayName            = displayName;
    
    UIViewController *cbController = [self viewControllerForActionType:cbAction];
    
    return cbController;
}

- (UIViewController*)startAnswerEngine:(NSString*)aeContext withDisplayName:(NSString*)displayName
{
    ECSAnswerEngineActionType *answerEngineAction = [ECSAnswerEngineActionType new];
    
    answerEngineAction.defaultQuestion = @"How do I get wireless Internet?";  // just an example, does nothing
    //answerEngineAction.journeybegin = [NSNumber numberWithBool:YES];
    answerEngineAction.actionId = @"";
    answerEngineAction.answerEngineContext = aeContext;
    answerEngineAction.navigationContext = @"";
    answerEngineAction.displayName = displayName;
    answerEngineAction.showSearchBar = YES;
    
    UIViewController *answerEngineController = [self viewControllerForActionType:answerEngineAction];
    ((ECSAnswerEngineViewController *)answerEngineController).parentNavigationContext = @"";
    
    return answerEngineController;
}

- (UIViewController*)startAnswerEngine:(NSString *)aeContext
                       withDisplayName:(NSString *)displayName
                         showSearchBar:(BOOL)showSearchBar
{
    ECSAnswerEngineActionType *answerEngineAction = [ECSAnswerEngineActionType new];
    
    answerEngineAction.defaultQuestion = @"How do I get wireless Internet?";  // just an example, does nothing
    //answerEngineAction.journeybegin = [NSNumber numberWithBool:YES];
    answerEngineAction.actionId = @"";
    answerEngineAction.answerEngineContext = aeContext;
    answerEngineAction.navigationContext = @"";
    answerEngineAction.displayName = displayName;
    answerEngineAction.showSearchBar = showSearchBar;
    
    UIViewController *answerEngineController = [self viewControllerForActionType:answerEngineAction];
    ((ECSAnswerEngineViewController *)answerEngineController).parentNavigationContext = @"";
    
    return answerEngineController;
}

- (UIViewController*)startSurvey:(NSString*)formName
{
    if (!formName || formName.length == 0) {
        ECSLogError(self.logger,@"startSurvey: Form name must be specified!");
        return nil;
    }
    
    ECSFormActionType *formAction = [ECSFormActionType new];
    formAction.actionId = formName;  // kwashington: Can't load the Form Synchronously, so set the actionId to the formName so the ECSFormViewController can do that in viewDidLoad()
    formAction.navigationContext = @"personas";

    UIViewController *formController = [self viewControllerForActionType:formAction];
    
    return formController;
}

- (UIViewController*)startUserProfile
{
    ECSActionType *profileAction = [ECSActionType new];
    profileAction.type = ECSActionTypeProfile;
    profileAction.actionId = self.userDisplayName;
    
    UIViewController *profileController = [self viewControllerForActionType:profileAction];
    
    return profileController;
}

- (UIViewController*)startEmailMessage
{
    ECSMessageActionType *messageAction = [ECSMessageActionType new];
    messageAction.actionId = @"";
    messageAction.email = ECSLocalizedString(@"callcenter@humanify.com", @"callcenter@humanify.com");
    messageAction.messageHeader = ECSLocalizedString(@"Leave a Message", @"Leave a Message");
    messageAction.hoursText = ECSLocalizedString(@"The Call Center is open between the hours of 8:00 AM and 8:00 PM.", @"The Call Center is open between the hours of 8:00 AM and 8:00 PM.");
    messageAction.messageText = ECSLocalizedString(@"The call center is closed!", @"The call center is closed!");
    messageAction.emailSubject = ECSLocalizedString(@"Important Message", @"Important Message");
    messageAction.emailButtonText = ECSLocalizedString(@"Submit Message", @"Submit Message");
    
    return [self startEmailMessage:messageAction];
}

- (UIViewController*)startEmailMessage:(ECSActionType *)messageAction
{
    UIViewController *messageController = [self viewControllerForActionType:messageAction];
    return messageController;
}

- (UIViewController*)startSMSMessage
{
    ECSSMSActionType *smsAction = [ECSSMSActionType new];
    smsAction.actionId = @"";
    
    UIViewController *smsController = [self viewControllerForActionType:smsAction];
    
    return smsController;
}

- (UIViewController*)startWebPage:(NSString *)url
{
    ECSWebActionType *webAction = [ECSWebActionType new];
    webAction.actionId = @"";
    webAction.url = url;
    
    UIViewController *webController = [self viewControllerForActionType:webAction];
    
    return webController;
}

- (UIViewController*)startAnswerEngineHistory
{
    ECSActionType *aeAction = [ECSActionType new];
    aeAction.type = ECSActionTypeAnswerHistory;
    aeAction.actionId = @"";
    
    UIViewController *aeController = [self viewControllerForActionType:aeAction];
    
    return aeController;
}

- (UIViewController*)startChatHistory
{
    ECSActionType *chistAction = [ECSActionType new];
    chistAction.type = ECSActionTypeChatHistory;
    chistAction.actionId = @"";
    
    UIViewController *chistController = [self viewControllerForActionType:chistAction];
    
    return chistController;
}

- (UIViewController*)startSelectExpertChat
{
    ECSActionType *expertAction = [ECSActionType new];
    expertAction.type = ECSActionTypeSelectExpertChat;
    expertAction.actionId = @"";
    expertAction.displayName = @"Chat With an Expert";
    
    UIViewController *expertController = [self viewControllerForActionType:expertAction];
    
    return expertController;
}

- (UIViewController*)startSelectExpertVideo
{
    ECSActionType *expertAction = [ECSActionType new];
    expertAction.type = ECSActionTypeSelectExpertVideo;
    expertAction.actionId = @"";
    expertAction.displayName = @"VideoChat With an Expert";
    
    UIViewController *expertController = [self viewControllerForActionType:expertAction];
    
    return expertController;
}

- (UIViewController*)startSelectExpertAndChannel
{
    ECSActionType *expertAction = [ECSActionType new];
    expertAction.type = ECSActionTypeSelectExpertAndChannel;
    expertAction.actionId = @"";
    expertAction.displayName = @"Select an Expert";
    
    UIViewController *expertController = [self viewControllerForActionType:expertAction];
    
    return expertController;
}

//- (void)setDebugCallback
//{
//    NSUInteger c;
//    NSString *format;
//    ECSLog(c, format);
//}

- (void)setLoggingCallback:(void(^ _Nullable)(ECSLogLevel level, NSString * _Nonnull message))callback
{
    self.logger.handler = callback;
}

#pragma mark VoiceIT Functions

//- (void)voiceAuthRequested:(NSString *)username callback:(void (^)(NSString *))authCallback {
//    // VoiceIT SDK. Call callback with response.
//    ECSVoiceItManager *voiceItManager = [[ECSInjector defaultInjector] objectForClass:[ECSVoiceItManager class]];
//    if ([voiceItManager isInitialized]) {
//        [voiceItManager authenticateAction:authCallback];
//    } else {
//        [voiceItManager configure:username];
//        [voiceItManager authenticateAction:authCallback];
//    }
//}
//
//- (void)recordNewEnrollment {
//    // VoiceIT SDK. Call callback with response.
//    ECSVoiceItManager *voiceItManager = [[ECSInjector defaultInjector] objectForClass:[ECSVoiceItManager class]];
//    if ([voiceItManager isInitialized]) {
//        [voiceItManager recordNewEnrollment];
//    } else {
//        [voiceItManager configure:[self userName]];
//        [voiceItManager recordNewEnrollment];
//    }
//}
//
//- (void)clearEnrollments {
//    // VoiceIT SDK. Call callback with response.
//    ECSVoiceItManager *voiceItManager = [[ECSInjector defaultInjector] objectForClass:[ECSVoiceItManager class]];
//    if ([voiceItManager isInitialized]) {
//        [voiceItManager clearEnrollments];
//    } else {
//        [voiceItManager configure:[self userName]];
//        [voiceItManager clearEnrollments];
//    }
//}

#pragma mark API Function Calls

/**
 @discussion Starts a new journey. All future breadcrumbs and API calls will use the same journeyID generated by this call. Subsequent calls will create a new journeyID.
 @param completion Returns the journey as a NSString an any errors encountered
 */
- (void) startJourneyWithCompletion:(void (^)(NSString *, NSError *))completion
{
//    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    
    [self startJourneyWithName:nil pushNotificationId:nil context:nil completion:completion];
}

/**
  @discussion Starts a new journey. All future breadcrumbs and API calls will use the same journeyID generated by this call. Subsequent calls will create a new journeyID.
  @param theName Name this journey. This name is displayed in reporting and analytics.
  @param thePushId A push notification ID (optional). This enables push notification functionality on this journey if the feature is enabled on your server.
  @param theContext The journey context to use. Context is used to determine which Journey Manager rules may act based on actions taken while on this journey.
  @param completion Returns the journey as a NSString an any errors encountered
 */
- (void) startJourneyWithName:(NSString *)theName
           pushNotificationId:(NSString *)thePushId
                      context:(NSString *)theContext
                   completion:(void (^)(NSString *, NSError *))completion
{
    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    
    [sessionManager setupJourneyWithName:theName
                      pushNotificationId:thePushId
                                 context:theContext
                              completion:^(ECSStartJourneyResponse *response, NSError* error)
     {
         if ( error || ![response isKindOfClass:[ECSStartJourneyResponse class]]) {
             
             if( completion ) {
                 completion(nil, error);
             }
             
         } else {
             
             if( response.journeyID && response.journeyID.length > 0 ) {
                 
                 // Set the global journeyID
                 //self.journeyID = response.journeyID;
                 sessionManager.journeyID = response.journeyID;
                 
                 if( completion )
                 {
                     completion(response.journeyID, error);
                 }
                 
             } else {
                 
                 if( completion ) {
                     completion(nil, error);
                 }
             }
         }
     }];
}
/**
 @desc Sets the context on the current journey. Context is used to determine which Journey Manager rules may act based on actions taken while on this journey.
 @param theContext The context value to set for the current journey
 @param completion Returns the response object or an error if one occurred
 */
- (void) setJourneyContext:(NSString *)theContext
            withCompletion:(void(^)(ECSJourneyAttachResponse *response, NSError *error))completion
{
    ECSURLSessionManager *sessionManager = [[EXPERTconnect shared] urlSession];
    
    [sessionManager setJourneyContext:theContext completion:^(ECSJourneyAttachResponse *response, NSError *error)
    {
        if(completion) completion(response, error);
    }];
}

// Unit Test: EXPERTconnectTests::testLoginWithEmailID
- (void) login:(NSString *) username withCompletion:(void (^)(ECSForm *, NSError *))completion {
    
    //[self setUserIdentityToken:nil]; // Kill the token (we want it to fetch another)
    
    [self setUserName:username];

    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    [sessionManager getFormByName:@"userprofile" withCompletion:^(ECSForm *form, NSError *error) {
        if (form && form.formData)
        {
            for (ECSFormItem *item in form.formData)
            {
                if ([item.metadata isEqualToString:@"profile.fullname"])
                {
                    self.userDisplayName = item.formValue;
                    break;
                }
                else if ([item.metadata isEqualToString:@"profile.firstname"] && !self.userDisplayName )
                {
                    self.userDisplayName = item.formValue;
                    break;
                }
                else if ([item.metadata isEqualToString:@"profile.lastname"] && !self.userDisplayName )
                {
                    self.userDisplayName = item.formValue;
                    break;
                }
            }
            
            completion(form, error);
        }
        else
        {
            completion(nil, error);
        }
    }];
}

- (void)logout {
    // In case the log has been wrapped by the host app, let's re-display configuration for the next log:
    ECSConfiguration *configuration = [[ECSInjector defaultInjector] objectForClass:[ECSConfiguration class]];
    //ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    
    // Log config for debugging:
    ECSLogVerbose(self.logger,@"SDK Performing logout for user %@ with configuration:\nhost: %@\ncafeXHost: %@\nappName: %@\nappVersion: %@\nappId: %@\nclientID: %@\ndefaultNavigationContext: %@", [self userName], configuration.host, configuration.cafeXHost, configuration.appName, configuration.appVersion, configuration.appId, configuration.clientID, configuration.defaultNavigationContext);
    
    [self setUserAvatar:nil];
    [self setUserName:nil];
}

-(void)recievedUnrecognizedAction:(NSString *)action {
    [self.workflow receivedUnrecognizedAction:action];
}

#pragma mark Agent Availability / Call skill detail Functions

// Unit Test: EXPERTconnectTests::testGetDetailsForExpertSkill
/**
 @desc Get chat/call skill details such as availability, estimated wait time, open/closed status. See the definition of the ECSSkillDetail object for details on particular fields
 @param skill The chat or call skill 
 @param completion Returns the skill data or an error if one occurred.
 */
- (void) getDetailsForExpertSkill:(NSString *)skill
                 completion:(void(^)(ECSSkillDetail *details, NSError *error))completion
{
    ECSURLSessionManager *sessionManager = [[EXPERTconnect shared] urlSession];
    
    [sessionManager getDetailsForExpertSkill:skill
                                  completion:^(NSDictionary *response, NSError *error)
    {
        if(!error && [response isKindOfClass:[NSDictionary class]] ) {
            
            NSArray *dataArray = [response objectForKey:@"data"];
            NSArray *skillsArray = [ECSJSONSerializer arrayFromJSONArray:dataArray withClass:[ECSSkillDetail class]];
            ECSSkillDetail *skillDetails = skillsArray[0];
            
            completion( skillDetails, error );
            
        } else {
            
            completion( nil, error );
            
        }
    }];
}

//- (void) agentAvailabilityWithSkill:(NSString *)skill
//                         completion:(void(^)(NSDictionary *status, NSError *error))completion
//{
//    ECSURLSessionManager *sessionManager = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
//    [sessionManager getDetailsForSkill:skill
//                            completion:^(NSDictionary *response, NSError *error)
//     {
//         NSLog(@"Got details for skill: %@", skill);
//         completion( response, error );
//     }];
//}
//- (void) getDetailsForSkill:(NSString *)skill
//                 completion:(void(^)(NSDictionary *details, NSError *error))completion
//{
//    ECSURLSessionManager *sessionManager = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
//    [sessionManager getDetailsForSkill:skill
//                            completion:^(NSDictionary *response, NSError *error)
//     {
//         NSLog(@"Got details for skill: %@", skill);
//         completion( response, error );
//     }];
//}

#pragma mark Workflow

- (void)startWorkflow:(NSString *)workFlowName
           withAction:(NSString *)actionType
              delgate:(id <ECSWorkflowDelegate>)workflowDelegate
       viewController:(UIViewController *)viewController {
    
    ECSConfiguration *ecsConfiguration = [[ECSInjector defaultInjector] objectForClass:[ECSConfiguration class]];
    
    ECSActionType *action = [ECSActionType new];
    action.type = actionType;
    action.actionId = @"";
    action.displayName = @"";
    
    ECSRootViewController *initialViewController = (ECSRootViewController *)[self viewControllerForActionType:action];
    
    if ([actionType isEqualToString:ECSActionTypeAnswerEngineString]) {
        initialViewController = (ECSRootViewController *)[self startAnswerEngine:ecsConfiguration.defaultAnswerEngineContext withDisplayName:action.displayName];
    }
    else if([actionType isEqualToString:ECSActionTypeFormString]) {
        initialViewController = (ECSRootViewController *)[self startSurvey:self.surveyFormName];
    }
    
    ECSWorkflowNavigation *navManager = [[ECSWorkflowNavigation alloc] initWithHostViewController:viewController];
    
    self.workflow = [[ECSWorkflow alloc] initWithWorkflowName:actionType
                                             workflowDelegate:workflowDelegate
                                            navigationManager:navManager];
    
    initialViewController.workflowDelegate = self.workflow;
    
    [navManager presentViewControllerInNavigationControllerModally:initialViewController
                                                          animated:YES
                                                        completion:nil];
    
}

- (void)startChatWorkflow:(NSString *)workFlowName
                withSkill:(NSString *)skillName
               withSurvey:(BOOL)shouldTakeSurvey
                  delgate:(id <ECSWorkflowDelegate>)workflowDelegate
           viewController:(UIViewController *)viewController {
    
    ECSRootViewController *initialViewController = (ECSRootViewController *)[self startChat:skillName
                                                                            withDisplayName:@"Chat"
                                                                                 withSurvey:shouldTakeSurvey];
    
    ECSWorkflowNavigation *navManager = [[ECSWorkflowNavigation alloc] initWithHostViewController:viewController];
    
    self.workflow = [[ECSWorkflow alloc] initWithWorkflowName:workFlowName
                                             workflowDelegate:workflowDelegate
                                            navigationManager:navManager];
    
    initialViewController.workflowDelegate = self.workflow;
    
    [navManager presentViewControllerInNavigationControllerModally:initialViewController
                                                          animated:YES
                                                        completion:nil];
}

// This version does not present a view controller.
- (UIViewController *)workflowViewWithAction:(NSString *)actionType
                                    delegate:(id <ECSWorkflowDelegate>)workflowDelegate {
    
    ECSConfiguration *ecsConfiguration = [[ECSInjector defaultInjector] objectForClass:[ECSConfiguration class]];
    
    ECSActionType *action = [ECSActionType new];
    action.type = actionType;
    action.actionId = @"";
    
    ECSRootViewController *initialViewController = (ECSRootViewController *)[self viewControllerForActionType:action];
    
    if ([actionType isEqualToString:ECSActionTypeAnswerEngineString]) {
        initialViewController = (ECSRootViewController *)[self startAnswerEngine:ecsConfiguration.defaultAnswerEngineContext withDisplayName:action.displayName];
    }
    else if([actionType isEqualToString:ECSActionTypeFormString]) {
        initialViewController = (ECSRootViewController *)[self startSurvey:self.surveyFormName];
    }
    
    ECSWorkflowNavigation *navManager = [[ECSWorkflowNavigation alloc] init];
    
    self.workflow = [[ECSWorkflow alloc] initWithWorkflowName:actionType
                                             workflowDelegate:workflowDelegate
                                            navigationManager:navManager];
    
    initialViewController.workflowDelegate = self.workflow;
    
    return initialViewController;
}

- (void) getTranscriptForConversation:(NSString *)conversationID withCompletion:(void(^)(NSArray *messages, NSError *error))completion {
    
    ECSURLSessionManager *urlSession = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
    
    [urlSession getChatHistoryDetailsForJourneyId:urlSession.journeyID withCompletion:^(ECSChatHistoryResponse *response, NSError *error)
    {
         if( ! error ) {
             
             NSArray *data = [response chatMessages];
             
             NSMutableArray *filteredData;
             
             if( data && data.count > 0 ) {
                 
                 if( conversationID ) {
                     
                     filteredData = [[NSMutableArray alloc] initWithCapacity:data.count];
                     
                     for (NSObject *message in data) {
                         
                         ECSChatMessage *tmpMsg = (ECSChatMessage *)message;
                         if( [tmpMsg.conversationId isEqualToString:conversationID] ) {
                             
                             [filteredData addObject:message];
                             
                         }
                     }
                     
                 } else {
                     
                     filteredData = [[NSMutableArray alloc] initWithArray:data];
                     
                 }
                 
                 completion(filteredData, nil);
                 
             } else {
                 // Empty array. Return nil.
                 completion(nil, nil);
             }
             
         } else {
             
             completion(nil, error);
             
         }
         
    }];
    
}

#pragma mark Breadcrumb Functions

/**
 @desc Send one breadcrumb to the Humanify server and wait for response.
 @param theBreadcrumb A breadcrumb object (contains all 4 data fields and more)
 @param theCompletion The server response (echos the breadcrumb fields back) or an error if one occurred
 */
- (void) breadcrumbSendOne:(ECSBreadcrumb *)theBreadcrumb
            withCompletion:(void(^)(ECSBreadcrumbResponse *, NSError *))theCompletion
{
    __block ECSBreadcrumb *blockBC = [theBreadcrumb copy];
    if([self sessionID] == nil)
    {
        ECSLogVerbose(self.logger,@"breadcrumbSendOne: No sessionID, fetching sessionID...");
        [self breadcrumbNewSessionWithCompletion:^(NSString *sessionID, NSError *error)
        {
            [self bc_internal_send_one_ex:blockBC withCompletion:theCompletion];
        }];
    }
    else
    {
        [self bc_internal_send_one_ex:blockBC withCompletion:theCompletion];
    }
    
//    // MAS - This contains the feature for automatic journeyID creation. Uncomment this when the feature is ready. 
//    // This block will attempt to send the breadcrumb. If that fails, it will attempt to fetch a breadcrumb
//    // session and possibly a journeyID. This would occur on older server versions (API 5.6 and older).
//    __weak typeof(self) weakSelf = self;
//    [self bc_internal_send_one_ex:theBreadcrumb withCompletion:^(ECSBreadcrumbResponse *response, NSError *error) {
//        
//         if( error || response.sessionId.length==0 || response.journeyId.length==0 )
//         {
//             [weakSelf breadcrumbNewSessionWithCompletion:^(NSString *sessionID, NSError *error) {
//                 
//                  [weakSelf bc_internal_send_one_ex:theBreadcrumb withCompletion:theCompletion];
//              }];
//         }
//         else
//         {
//             if(theCompletion) theCompletion(response, error);
//         }
//     }];
}

/**
 @desc Queue a bulk breadcrumb for sending. Bulked breadcrumbs will fire after the timer delay or X breadcrumbs
 have been queued as defined in config. Bulked breadcrumbs will not cause journeyManager actions or escalations.
 @param theBreadcrumb A breadcrumb object (contains all 4 data fields and more)
 */
- (void) breadcrumbQueueBulk:(ECSBreadcrumb *)theBreadcrumb
{
    [self breadcrumbWithAction:theBreadcrumb.actionType
                   description:theBreadcrumb.actionDescription
                        source:theBreadcrumb.actionSource
                   destination:theBreadcrumb.actionDestination
                   geolocation:theBreadcrumb.geoLocation];
}

- (void) breadcrumbWithAction: (NSString *)actionType
                  description: (NSString *)actionDescription
                       source: (NSString *)actionSource
                  destination: (NSString *)actionDestination
                  geolocation: (CLLocation *)geolocation
{
    // Build a new breadcrumb object.
    ECSBreadcrumb *breadcrumb = [[ECSBreadcrumb alloc] init];

    breadcrumb.actionType = actionType;
    breadcrumb.actionDescription = actionDescription;
    breadcrumb.actionSource = actionSource;
    breadcrumb.actionDestination = actionDestination;
    
    if (geolocation) [breadcrumb setGeoLocation:geolocation];
    
    // This block will create a breadcrumb session if one is not already created.
    if([self sessionID] == Nil)
    {
        ECSLogVerbose(self.logger,@"breadcrumbWithAction: No sessionID, fetching sessionID...");
        [self breadcrumbNewSessionWithCompletion:^(NSString *sessionID, NSError *error)
        {
            if( sessionID && !error)
            {
                ECSLogVerbose(self.logger,@"breadcrumbWithAction: Acquired sessionID.");
                [self bc_internal_queue_bulk:breadcrumb];
            }
            else
            {
                ECSLogVerbose(self.logger,@"breadcrumbWithAction: Failed to acquire a breadcrumb session or journey ID. Cannot send breadcrumb.");
            }
        }];
    }
    else
    {
        ECSLogVerbose(self.logger,@"breadcrumbWithAction: queueing breadcrumb...");
        [self bc_internal_queue_bulk:breadcrumb];
    }
}

/**
 @desc Immediately dispatches any bulk breadcrumbs still in the queue.
 */
- (void) breadcrumbDispatch
{
    [self breadcrumbDispatchWithCompletion:nil];
}

/**
 @desc Immediately dispatches any bulk breadcrumbs still in the queue.
 @param theCompletion The server response or an error if one occurred.
 */
- (void) breadcrumbDispatchWithCompletion:(void(^)(NSDictionary *response, NSError *error))theCompletion
{
    if (storedBreadcrumbs.count < 1)
    {
        return;
    }
    [breadcrumbTimer invalidate];
    breadcrumbTimer = nil;
    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    
    NSArray *breadcrumbsToSend = [storedBreadcrumbs copy];
    
    [sessionManager breadcrumbsAction:breadcrumbsToSend completion:theCompletion];
    
    // TODO: Possibly need to not wipe these everytime, maybe server down for limited time? Temporary error?
    storedBreadcrumbs = [[NSMutableArray alloc] init]; // Reset the array.
}

// Unit Test: EXPERTconnectTests::testBreadcrumbNewSession
- (void) breadcrumbNewSessionWithCompletion:(void(^)(NSString *, NSError *))completion
{
    // MAS - If we are in this function, it probably means we are on server version 5.6 or earlier.
    // Therefore, we can assume "automatic journeyId generation" is also not working.
    // This is why we will now attempt to manually start a journey.
    
    if(self.journeyID == Nil)
    {
        ECSLogVerbose(self.logger,@"breadcrumbNewSession: No journeyID. Fetching new journeyID...");
        [self startJourneyWithCompletion:^(NSString *journeyId, NSError *error)
         {
             if( !error && journeyId )
             {
                 ECSLogVerbose(self.logger,@"breadcrumbNewSession: Acquired journeyID. Now queuing breadcrumb...");
                 [self bc_internal_start_session:completion];
             }
             else
             {
                 if(completion) completion(nil, error);
             }
         }];
    }
    else
    {
        [self bc_internal_start_session:completion];
    }
}

/**
 Internal function for sending a breadcrumb. Assumes session & journey have been started.
 */
- (void) bc_internal_send_one_ex:(ECSBreadcrumb *)theBreadcrumb
                  withCompletion:(void(^)(ECSBreadcrumbResponse *, NSError *))theCompletion
{
    if( [self sessionID] == Nil )
    {
        ECSLogVerbose(self.logger,@"bc_internal_send_one_ex::Bailing. Fetching session or failed to get a session.");
        return;
    }
    
    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    if([self clientID])theBreadcrumb.tenantId = [self clientID];
    if(self.journeyID)theBreadcrumb.journeyId = self.journeyID;
    if([self sessionID])theBreadcrumb.sessionId = [self sessionID];
    theBreadcrumb.userId = (userManager.userToken ? userManager.userToken : userManager.deviceID);
    theBreadcrumb.creationTime = [NSString stringWithFormat:@"%lld",[@(floor(NSDate.date.timeIntervalSince1970 * 1000)) longLongValue]];
    if([self pushNotificationID])theBreadcrumb.pushNotificationId = self.pushNotificationID;
    
    [sessionManager breadcrumbActionSingle:[theBreadcrumb getProperties]
                                completion:^(ECSBreadcrumbResponse *json, NSError *error)
    {
        // MAS - If the response returned a breadcrumb session, store it.
        if(json.sessionId) self.sessionID = json.sessionId;

        if(theCompletion) theCompletion(json, error);
    }];
}

- (void) bc_internal_queue_bulk:(ECSBreadcrumb *)theBreadcrumb
{
    if( [self sessionID] == Nil )
    {
        ECSLogVerbose(self.logger,@"breadcrumbsAction::Bailing. Fetching session or failed to get a session.");
        return;
    }
    
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    if([self clientID])theBreadcrumb.tenantId = [self clientID];
    if(self.journeyID)theBreadcrumb.journeyId = self.journeyID;
    if(self.sessionID)theBreadcrumb.sessionId = [self sessionID];
    theBreadcrumb.userId = (userManager.userToken ? userManager.userToken : userManager.deviceID);
    theBreadcrumb.creationTime = [NSString stringWithFormat:@"%lld",[@(floor(NSDate.date.timeIntervalSince1970 * 1000)) longLongValue]];
    if([self pushNotificationID])theBreadcrumb.pushNotificationId = self.pushNotificationID;
    
    ECSLogVerbose(self.logger,@"breadcrumbsAction:: calling with actionType : %@", theBreadcrumb.actionType);

    if (!storedBreadcrumbs) storedBreadcrumbs = [[NSMutableArray alloc] init];
    [storedBreadcrumbs addObject:[theBreadcrumb getProperties]];
    
    ECSLogVerbose(self.logger,@"breadcrumb Properties: %@", [theBreadcrumb getProperties]);
    
    ECSConfiguration *config = [[ECSInjector defaultInjector] objectForClass:[ECSConfiguration class]];
    int breadcrumbCacheCount = (int)( config.breadcrumbCacheCount ? config.breadcrumbCacheCount : 1 );
    ECSLogVerbose(self.logger,@"breadcrumbWithAction::Cache time=%lu, count=%d.", (unsigned long)config.breadcrumbCacheTime, breadcrumbCacheCount);
    
    if (storedBreadcrumbs.count >= breadcrumbCacheCount )
    {
        ECSLogVerbose(self.logger,@"breadcrumbWithAction::Breadcrumb will be dispatched for sending.");
        [self breadcrumbDispatchWithCompletion:nil]; // Dispatch all breadcrumbs
    }
    else if(storedBreadcrumbs.count > 0 && !breadcrumbTimer && config.breadcrumbCacheTime > 0 )
    {
        ECSLogVerbose(self.logger,@"breadcrumbWithAction::Breadcrumb cached but not sent. Starting timer to send.");
        // Start a timer that fires after X time to send off the breadcrumbs.
        
        //NSDate *fireTime = [NSDate dateWithTimeIntervalSinceNow:config.breadcrumbCacheTime];
        breadcrumbTimer = [NSTimer scheduledTimerWithTimeInterval:config.breadcrumbCacheTime
                                                           target:self
                                                         selector:@selector(breadcrumbDispatch)
                                                         userInfo:nil
                                                          repeats:NO];
    }
    else
    {
        ECSLogVerbose(self.logger,@"breadcrumbWithAction::Breadcrumb cached but not sent.");
    }
}

- (void) bc_internal_start_session:(void(^)(NSString *, NSError *))completion
{
//    if( self.journeyID == Nil )
//    {
//        NSError *error = [NSError errorWithDomain:@"Breadcrumb New Session - Missing JourneyID."
//                                             code:1001
//                                         userInfo:nil];
//        completion(nil, error);
//        return;
//    }
    
    ECSLogVerbose(self.logger,@"breadcrumbNewSession - calling with journeyId : %@", self.journeyID);
    
    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    ECSBreadcrumbsSession *journeySession = [[ECSBreadcrumbsSession alloc] init];
    
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    
    if([self clientID])[journeySession setTenantId:[self clientID]];
    if([self journeyID])[journeySession setJourneyId:self.journeyID];
    [journeySession setDeviceId:userManager.deviceID];
    [journeySession setPlatform:@"iOS"];
    [journeySession setOSVersion:[[UIDevice currentDevice] systemVersion]];
    [journeySession setBrowserType:@"NA"];
    [journeySession setBrowserVersion:@"NA"];
    
    // Set phone number if one was present.
    if(_userCallbackNumber)[journeySession setPhonenumber:_userCallbackNumber];

    NSDictionary *properties = [journeySession getProperties];
    
    [sessionManager breadcrumbsSession:properties
                            completion:^(NSDictionary *decisionResponse, NSError *error)
    {
        
        if( error )
        {
            ECSLogError(self.logger,@"breadcrumbNewSession - Error: %@", error.description);
            if(completion) completion(nil, error);
        }
        else
        {
            ECSBreadcrumbsSession *journeySessionRes = [[ECSBreadcrumbsSession alloc]
                                                        initWithDic:decisionResponse];
            
            ECSLogVerbose(self.logger,@"breadcrumbNewSession - Value of sessionID is: %@", [journeySessionRes getSessionId]);
            
            // Set the global sessionId
            self.sessionID = [journeySessionRes getSessionId];
            sessionManager.breadcrumbSessionID = self.sessionID;
            
            if(completion) completion(self.sessionID, nil);
        }
    }];
}


@end
