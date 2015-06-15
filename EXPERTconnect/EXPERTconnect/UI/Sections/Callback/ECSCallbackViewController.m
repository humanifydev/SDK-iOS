//
//  ECSCallbackViewController.m
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import "ECSCallbackViewController.h"

#import "ECSButton.h"
#import "ECSCallbackActionType.h"
#import "ECSChannelConfiguration.h"
#import "ECSChannelCreateResponse.h"
#import "ECSSMSActionType.h"
#import "ECSCallbackSetupResponse.h"
#import "ECSCancelCallbackViewController.h"
#import "ECSConversationCreateResponse.h"
#import "ECSConversationLink.h"
#import "ECSDynamicLabel.h"
#import "ECSInjector.h"
#import "ECSLocalization.h"
#import "ECSUserManager.h"
#import "ECSTheme.h"
#import "ECSURLSessionManager.h"

#import "UIViewController+ECSNibLoading.h"

@interface ECSCallbackViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet ECSButton *requestCallButton;
@property (weak, nonatomic) IBOutlet UIView *toolbarContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarContainerBottomContstraint;
@property (weak, nonatomic) IBOutlet ECSDynamicLabel *headerLabel;
@property (weak, nonatomic) IBOutlet ECSDynamicLabel *disclaimerLabel;
@property (weak, nonatomic) IBOutlet UITextField *callbackTextField;
@property (strong, nonatomic) NSString *currentConversationId;

@property (strong, nonatomic) NSString *phoneNumberString;

@end

@implementation ECSCallbackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerForKeyboardNotifications];

    ECSTheme *theme = [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
    
    self.headerLabel.font = theme.bodyFont;
    self.headerLabel.textColor = theme.primaryTextColor;
    self.disclaimerLabel.font = theme.captionFont;
    self.disclaimerLabel.textColor = theme.secondaryTextColor;
    self.callbackTextField.tintColor = theme.primaryColor;
    
    self.requestCallButton.enabled = NO;

    if (self.displaySMSOption)
    {
        self.navigationItem.title = ECSLocalizedString(ECSLocalizeSMSNavigationTitle, @"SMS Message");
        self.headerLabel.text = ECSLocalizedString(ECSLocalizeRequestSMSText,
                                                   @"Enter your phone number to receive a SMS:");
        self.disclaimerLabel.text = ECSLocalizedString(ECSLocalizeRequestSMSDisclaimerText,
                                                       @"Carrier voice and data rates may apply");
        [self.requestCallButton setTitle:ECSLocalizedString(ECSLocalizeRequestSMSButton, @"Request a SMS")
                                forState:UIControlStateNormal];
    }
    else
    {
        self.navigationItem.title = ECSLocalizedString(ECSLocalizeCallNavigationTitle, @"Phone Call");
        self.headerLabel.text = ECSLocalizedString(ECSLocalizeRequestCallText,
                                                   @"Enter your phone number to receive a call:");
        self.disclaimerLabel.text = ECSLocalizedString(ECSLocalizeRequestCallDisclaimerText,
                                                       @"Carrier voice and data rates may apply");
        [self.requestCallButton setTitle:ECSLocalizedString(ECSLocalizeRequestCallButton, @"Request a Phone Call")
                                forState:UIControlStateNormal];
    }
    
    
    NSLayoutConstraint *leftContent = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                   attribute:NSLayoutAttributeLeft
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeLeft
                                                                  multiplier:1.0f
                                                                    constant:0.0f];
    NSLayoutConstraint *rightContent = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                    attribute:NSLayoutAttributeRight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeRight
                                                                   multiplier:1.0f
                                                                     constant:0.0f];
    
    [self.view addConstraints:@[leftContent, rightContent]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.requestCallButton.enabled = YES;
    self.callbackTextField.enabled = YES;
    [self.callbackTextField becomeFirstResponder];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)requestCallTapped:(id)sender
{
    ECSURLSessionManager *sessionManager = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
    
    [self.requestCallButton setTitle:ECSLocalizedString(ECSLocalizeProcessingButton, @"Processing...")
                            forState:UIControlStateDisabled];
    
    self.requestCallButton.enabled = NO;
    self.callbackTextField.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    
    if ([self.actionType isKindOfClass:[ECSCallbackActionType class]])
    {
        [sessionManager startConversationForAction:self.actionType
                                    andAlwaysCreate:YES
                                     withCompletion:^(ECSConversationCreateResponse *conversation, NSError *error) {
                                         [weakSelf setupChannelOfType:@"Callback"
                                                     withConversation:conversation
                                                           completion:^(ECSChannelCreateResponse *setupResponse, NSError *error) {
                                                               [weakSelf handleCallbackRepsonse:setupResponse withError:error];
                                                           }];
                                     }];
    }
    else if ([self.actionType isKindOfClass:[ECSSMSActionType class]])
    {
        [sessionManager startConversationForAction:self.actionType
                                andAlwaysCreate:YES
                                     withCompletion:^(ECSConversationCreateResponse *conversation, NSError *error) {
                                         [weakSelf setupChannelOfType:@"SMS"
                                                     withConversation:conversation
                                                           completion:^(ECSChannelCreateResponse *setupResponse, NSError *error) {
                                                               [weakSelf handleCallbackRepsonse:setupResponse withError:error];
                                                           }];
                                     }];

      }
}

- (void)setupChannelOfType:(NSString*)channelType
          withConversation:(ECSConversationCreateResponse*)conversation
                completion:(void (^)(ECSChannelCreateResponse *response, NSError *error))completion
{
    ECSURLSessionManager *urlSession = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
    if (conversation.conversationID.length == 0)
    {
        return;
    }
    
    ECSUserManager *userManager = [[ECSInjector defaultInjector] objectForClass:[ECSUserManager class]];
    ECSChannelConfiguration *configuration = [ECSChannelConfiguration new];
    
    ECSCallbackActionType *callbackAction = (ECSCallbackActionType*)self.actionType;
    
    if ([callbackAction.agentId isKindOfClass:[NSString class]] && callbackAction.agentId.length > 0)
    {
        configuration.to = callbackAction.agentId;
    }
    else
    {
        configuration.to = callbackAction.agentSkill;
    }
//#ifdef DEBUG
//    configuration.to = @"Calls for erik_mktwebextc";
//#endif
    
    configuration.from = userManager.userToken;
    configuration.subject = @"help";
    configuration.sourceType = channelType;
    
    NSString *phoneNumber = [[self.callbackTextField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                             componentsJoinedByString:@""];
    
    if (phoneNumber.length > 10)
    {
        configuration.sourceAddress = [NSString stringWithFormat:@"+%@", phoneNumber];
    }
    else
    {
        configuration.sourceAddress = phoneNumber;
    }
    
    configuration.mediaType = @"Voice";
    configuration.deviceId = userManager.deviceID;
    configuration.location = @"Mobile";
    configuration.priority = @1;
    
    self.currentConversationId = [conversation.conversationID copy];
    NSString *url = conversation.channelLink;
    
    if (url)
    {
        [urlSession setupChannel:configuration inConversation:url
                      completion:completion];
    }
}

- (void)handleCallbackRepsonse:(ECSChannelCreateResponse*)response withError:(NSError*)error
{
    if (self.skipConfirmationView)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (self.displaySMSOption)
    {
        [self.requestCallButton setTitle:ECSLocalizedString(ECSLocalizeRequestSMSButton, @"Request a SMS")
                                forState:UIControlStateDisabled];
    }
    else
    {
        [self.requestCallButton setTitle:ECSLocalizedString(ECSLocalizeRequestCallButton, @"Request a Phone Call")
                                forState:UIControlStateDisabled];
    }

    if (error)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ECSLocalizedString(ECSLocalizeError, @"Error")
                                                            message:ECSLocalizedString(ECSLocalizeErrorText, @"Error Text")
                                                           delegate:nil
                                                  cancelButtonTitle:ECSLocalizedString(ECSLocalizedOkButton, @"OK")
                                                  otherButtonTitles:nil];
        [alertView show];
        self.requestCallButton.enabled = YES;
        self.callbackTextField.enabled = YES;
    }
    else
    {
        
        ECSCancelCallbackViewController *cancelCallback = [ECSCancelCallbackViewController ecs_loadFromNib];
        
        cancelCallback.closeChannelURL = ((ECSConversationCreateResponse*)response).closeLink;

        cancelCallback.phoneNumber = self.callbackTextField.text;
        cancelCallback.displaySMSOption = self.displaySMSOption;
        cancelCallback.waitTime = response.estimatedWait;
        cancelCallback.actionId = self.actionType.actionId;
        [self.navigationController pushViewController:cancelCallback animated:YES];

    }
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.phoneNumberString = @"";
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.phoneNumberString = @"";
    self.requestCallButton.enabled = NO;
    return YES;
}

- (NSString*)formatPhoneString:(NSString*)string
{
    NSString *newString = nil;
    if (string.length <= 4)
    {
        newString = string;
    }
    else if (string.length <= 7)
    {
        NSInteger remainingLength = string.length - 4;
        newString = [NSString stringWithFormat:@"%@-%@",
                               [string substringWithRange:NSMakeRange(0, remainingLength)],
                               [string substringWithRange:NSMakeRange(remainingLength, 4)]];
    }
    else if (string.length <= 10)
    {
        NSInteger remainingLength = string.length - 7;
        newString = [NSString stringWithFormat:@"(%@) %@-%@",
                               [string substringWithRange:NSMakeRange(0, remainingLength)],
                               [string substringWithRange:NSMakeRange(remainingLength, 3)],
                               [string substringWithRange:NSMakeRange(remainingLength + 3, 4)]];
    }
    else
    {
        NSInteger remainingLength = string.length - 10;
        newString = [NSString stringWithFormat:@"+%@ (%@) %@-%@",
                     [string substringWithRange:NSMakeRange(0, remainingLength)],
                     [string substringWithRange:NSMakeRange(remainingLength, 3)],
                     [string substringWithRange:NSMakeRange(remainingLength + 3, 3)],
                     [string substringWithRange:NSMakeRange(remainingLength + 6, 4)]];
    }
    
    if (string.length >= 10)
    {
        self.requestCallButton.enabled = YES;
    }
    else
    {
        self.requestCallButton.enabled = NO;
    }
    
    return newString;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSMutableCharacterSet *phoneNumberSet = [NSMutableCharacterSet decimalDigitCharacterSet];
    
    NSString *trimedReplacementString = [string stringByTrimmingCharactersInSet:[phoneNumberSet invertedSet]];
    
    if (trimedReplacementString.length == string.length)
    {
        NSString *replacementString = [textField.text stringByReplacingCharactersInRange:range withString:trimedReplacementString];
        
        NSCharacterSet *nonPhoneNumberSet = [phoneNumberSet invertedSet];
        NSString *numberOnlyString = [[replacementString componentsSeparatedByCharactersInSet:nonPhoneNumberSet] componentsJoinedByString:@""];

        textField.text = [self formatPhoneString:numberOnlyString];
    }
    
    return NO;
}

#pragma mark - Keyboard

- (void)registerForKeyboardNotifications
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
}

- (void)keyboardWillChangeFrame:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *animationTime = userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey];
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:[animationTime floatValue] animations:^{
        [UIView setAnimationCurve:[animationCurve intValue]];
        UIEdgeInsets insets = self.scrollView.contentInset;
        self.toolbarContainerBottomContstraint.constant = endFrame.size.height;
        insets.bottom = endFrame.size.height + self.toolbarContainer.frame.size.height;
        self.scrollView.contentInset = insets;
        self.scrollView.scrollIndicatorInsets = insets;
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *animationTime = userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey];
    
    [UIView animateWithDuration:[animationTime floatValue] animations:^{
        [UIView setAnimationCurve:[animationCurve intValue]];
        UIEdgeInsets insets = self.scrollView.contentInset;
        self.toolbarContainerBottomContstraint.constant = 0;
        insets.bottom = 0;
        self.scrollView.contentInset = insets;
        self.scrollView.scrollIndicatorInsets = insets;
        [self.view layoutIfNeeded];
    }];
    
}


@end
