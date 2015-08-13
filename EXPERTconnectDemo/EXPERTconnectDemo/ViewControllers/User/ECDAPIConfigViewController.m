//
//  ECDAPIConfigViewController.m
//  EXPERTconnectDemo
//
//  Created by Ken Washington on 8/12/15.
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//
#import "ECDAdHocAnswerEngineContextPicker.h"
#import "ECDAPIConfigViewController.h"
#import "ECDLocalization.h"

#import <EXPERTconnect/EXPERTconnect.h>
#import <EXPERTconnect/ECSTheme.h>
#import <EXPERTconnect/ECSUserProfile.h>

static NSString * const kReadConfigUrlPath = @"/appconfig/v1/read_rconfig?name={name}";
static NSString * const kClearCacheUrlPath = @"/answerengine/v1/clear_cache";

@interface ECDAPIConfigViewController ()

@property (weak, nonatomic) IBOutlet UITextField *configNameField;
@property (weak, nonatomic) IBOutlet UITextField *configEndpointField;
@property (weak, nonatomic) IBOutlet UITextField *configValueField;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *askQuestionButton;
@property (weak, nonatomic) IBOutlet UITextView *answerEngineResponseTextView;
@property (weak, nonatomic) IBOutlet ECDAdHocAnswerEngineContextPicker *selectAnswerEngineContextPicker;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *topQuestions;

@end

@implementation ECDAPIConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeFields];

    NSString *endpoint = [kReadConfigUrlPath
                          stringByReplacingOccurrencesOfString:@"{name}" withString:self.configNameField.text];
    
    __weak typeof(self) weakSelf = self;
    
    ECSCodeBlock whenCompleted = ^(NSString *response, NSError *error)   {
        weakSelf.configValueField.text = response;
    };
    
    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    [sessionManager getResponseFromEndpoint:endpoint withCompletion:whenCompleted];
}

-(void) initializeFields {
    self.answerEngineResponseTextView.text = @"";

    // Set the tintColor so we can see the cursor clear;
    //
    self.configNameField.tintColor = UIColor.blueColor;
    self.configEndpointField.tintColor = UIColor.blueColor;
    self.configValueField.tintColor = UIColor.blueColor;
    self.answerEngineResponseTextView.tintColor = UIColor.blueColor;
    
    // Round button corners
    CALayer *btnLayer = [self.submitButton layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:5.0f];
    
    btnLayer = [self.refreshButton layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:5.0f];
    
    btnLayer = [self.askQuestionButton layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:5.0f];
    
    [self.submitButton addTarget:self
                          action:@selector(submitButtonTapped:)
                forControlEvents:UIControlEventTouchUpInside];
    
    [self.refreshButton addTarget:self
                           action:@selector(refreshButtonTapped:)
                 forControlEvents:UIControlEventTouchUpInside];
    
    [self.askQuestionButton addTarget:self
                           action:@selector(askQuestionButtonTapped:)
                 forControlEvents:UIControlEventTouchUpInside];

    
    [self.selectAnswerEngineContextPicker setup];


    self.tableView.delegate = self;
    [self refreshButtonTapped:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.topQuestions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"Top Questions";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [self.topQuestions objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.answerEngineResponseTextView.text = [self.topQuestions objectAtIndex:indexPath.row];
    NSLog(@"Row Selected: %d", indexPath.row);
}

- (void)submitButtonTapped:(UIButton*)button
{
    NSString *endpoint = [[self.configEndpointField.text
                           stringByReplacingOccurrencesOfString:@"{name}" withString:self.configNameField.text]
                           stringByReplacingOccurrencesOfString:@"{value}" withString:self.configValueField.text];
    
    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    
    __weak typeof(self) weakSelf = self;
    
    ECSCodeBlock whenCompleted = ^(NSString *response, NSError *error)   {
        NSString *title = ECSLocalizedString(ECSLocalizeInfoKey, @"Info");
        NSString *profileMessage = ECDLocalizedString(ECDLocalizeConfigWasUpdatedKey, @"Config Value was updated:");
        NSString *message = [NSString stringWithFormat:[profileMessage stringByAppendingString:@": %@"], response];
        
        [weakSelf showAlert:title withMessage:message];
    };
    
    ECSCodeBlock whenUpdated = ^(NSString *response, NSError *error)   {
        NSString *profileMessage = ECDLocalizedString(ECDLocalizeConfigWasUpdatedKey, @"Config Value was updated:");
        NSLog(@"%@", profileMessage);
        
        // Now that the Config Value has been updated, Clear the Answer Engine Cache so our next request
        // will go against the requested Answer Engine Type (Synthetix / IntelliResponse)
        //
        [sessionManager getResponseFromEndpoint:kClearCacheUrlPath withCompletion:whenCompleted];
    };
    
    [sessionManager getResponseFromEndpoint:endpoint withCompletion:whenUpdated];
}

- (void)refreshButtonTapped:(UIButton*)button
{
    NSString *context = self.selectAnswerEngineContextPicker.currentSelection;
    NSNumber *num_questions = [NSNumber numberWithInt:4];
    
    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    
    __weak typeof(self) weakSelf = self;
    
    [sessionManager getAnswerEngineTopQuestions:num_questions forContext:context withCompletion:^(NSArray *response, NSError *error)   {
        weakSelf.topQuestions = response;
        
        [weakSelf.tableView reloadData];
        
        NSLog(@"Received %d Top Questions", [response count]);
    }];
}

- (void)askQuestionButtonTapped:(UIButton*)button
{
    NSString *question = self.answerEngineResponseTextView.text;
    NSString *context = self.selectAnswerEngineContextPicker.currentSelection;
    
    ECSURLSessionManager* sessionManager = [[EXPERTconnect shared] urlSession];
    
    [sessionManager getAnswerForQuestion:question inContext:context parentNavigator:@"" actionId:@"" questionCount:0
                              customData:nil completion:^(ECSAnswerEngineResponse *response, NSError *error) {
        
        NSLog(@"Received AnswerEngine Response: %@", @"response.answerContent");
                                  
        self.answerEngineResponseTextView.text = response.answer;
    }];
}

- (void) showAlert:(NSString *)title withMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:ECSLocalizedString(ECSLocalizedOkButton, @"Ok Button")
                                          otherButtonTitles:nil];
    [alert show];
}

@end