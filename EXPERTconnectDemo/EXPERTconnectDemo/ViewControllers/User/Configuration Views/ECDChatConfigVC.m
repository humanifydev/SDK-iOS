//
//  ECDChatConfigVC.m
//  EXPERTconnectDemo
//
//  Created by Michael Schmoyer on 6/10/16.
//  Copyright © 2016 Humanify, Inc. All rights reserved.
//

#import "ECDChatConfigVC.h"
#import "ECDLocalization.h"

@interface ECDChatConfigVC () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>

@end

@implementation ECDChatConfigVC

static NSString *const lastChatSkillKey = @"lastSkillSelected";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _chatActive = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(chatStarted:)
                                                  name:ECSChatStartedNotification
                                                object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatEnded:)
                                                 name:ECSChatEndedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatMessageReceived:)
                                                 name:ECSChatMessageReceivedNotification
                                               object:nil];
    
    self.pickerChatSkill.delegate = self;
    self.pickerChatSkill.dataSource = self;
    
    self.txtHMargin.delegate = self;
    self.txtVMargin.delegate = self;
    self.txtCornerRadius.delegate = self;
    
    // Attempt to load the selected skill for the selected environment
    currentChatSkill = [[NSUserDefaults standardUserDefaults]
                        stringForKey:[NSString stringWithFormat:@"%@_%@", currentEnvironment, lastChatSkillKey]];
    
    // Select the current skill in the flipper control.
    int currentRow = 0;
    rowToSelect = 0;
    if(currentChatSkill != nil)  {
        for(NSString* skill in chatSkillsArray) {
            if([skill isEqualToString:currentChatSkill])  {
                selectedRow = currentRow;
                break;
            }
            currentRow++;
        }
    }
    
    self.navigationItem.title = @"Humanify Chat";
    
    [self.btnStartChat setBackgroundColor:[EXPERTconnect shared].theme.buttonColor];
    [self.btnEndChat setBackgroundColor:[EXPERTconnect shared].theme.buttonColor];
    [self.btnStartChat setTitleColor:[EXPERTconnect shared].theme.buttonTextColor forState:UIControlStateNormal];
    [self.btnEndChat setTitleColor:[EXPERTconnect shared].theme.buttonTextColor forState:UIControlStateNormal];
     
     self.chatSkillLabel.text =  ECDLocalizedString(ECDLocalizedChatSkillLabel, @"Chat Skill");
     self.avatarImagesLabel.text =  ECDLocalizedString(ECDLocalizedStartShowAvatarImagesLabel, @"Avatar Images");
     self.timeStampLabel.text =  ECDLocalizedString(ECDLocalizedStartShowChatTimeStampLabel, @"Time Stamp");
     self.chatBubblesLabel.text =  ECDLocalizedString(ECDLocalizedStartShowChatBubbleTailsLabel, @"Chat Bubbles");
     self.customNavBarButtonsLabel.text =  ECDLocalizedString(ECDLocalizedCustomNavBarButtonsLabel, @"Custom Nav Bar Buttons");
     self.useImageForSendButtonLabel.text =  ECDLocalizedString(ECDLocalizedUseImageForSendButtonLabel, @"Use Image For Send Button");
     self.showImageUploadButtonLabel.text =  ECDLocalizedString(ECDLocalizedImageUploadButtonLabel, @"Image Upload Button");
     
     [self.btnStartChat setTitle:ECDLocalizedString(ECDLocalizedStartChatLabel, @"Start Chat") forState:UIControlStateNormal];
     [self.btnEndChat setTitle:ECDLocalizedString(ECDLocalizedEndChatLabel, @"End Chat") forState:UIControlStateNormal];
    
    [self.btnEndChat setEnabled:NO];
    
    [self.txtHMargin setText:[NSString stringWithFormat:@"%ld",(long)[EXPERTconnect shared].theme.chatBubbleHorizMargins]];
    [self.txtVMargin setText:[NSString stringWithFormat:@"%ld",(long)[EXPERTconnect shared].theme.chatBubbleVertMargins]];
    [self.txtCornerRadius setText:[NSString stringWithFormat:@"%ld",(long)[EXPERTconnect shared].theme.chatBubbleCornerRadius]];
}

- (void)viewWillAppear:(BOOL)animated {
    [self setupPickerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnStartChat_Touch:(id)sender {
    
    NSString *chatSkill = chatSkillsArray[selectedRow];
    
    NSLog(@"Test Harness::Chat Config - Starting Ad-Hoc Chat with Skill: %@", chatSkill);
    
    ECSBreadcrumb *chatBC = [[ECSBreadcrumb alloc] initWithAction:@"Start Chat"
                                                      description:@"Starting an ad-hoc chat from Test Harness"
                                                           source:@"Test Harness - iOS"
                                                      destination:@""];
    
    [[EXPERTconnect shared] breadcrumbSendOne:chatBC withCompletion:nil];
    
    // MAS - Oct-2015 - For demo app, do not show survey after chat. Workflows not implemented yet.
    /*NSString *languageLocale = [NSString stringWithFormat:@"%@_%@",
                                [[NSLocale preferredLanguages] objectAtIndex:0],
                                [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];*/
    
    [EXPERTconnect shared].theme.showChatBubbleTails = self.optChatBubble.on;
    [EXPERTconnect shared].theme.showAvatarImages = self.optAvatarImages.on;
    [EXPERTconnect shared].theme.showChatTimeStamp = self.optTimestamp.on;
    [EXPERTconnect shared].theme.showChatImageUploadButton = self.optImageUploadButton.on;
    [EXPERTconnect shared].theme.chatSendButtonUseImage = self.optSendButtonImage.on;
    
    [EXPERTconnect shared].theme.chatBubbleHorizMargins = [self.txtHMargin.text intValue];
    [EXPERTconnect shared].theme.chatBubbleVertMargins = [self.txtVMargin.text intValue];
    [EXPERTconnect shared].theme.chatBubbleCornerRadius = [self.txtCornerRadius.text intValue];
    
    // Create the chat view
    if( !self.chatController || !_chatActive )
    {
        self.chatController = (ECSChatViewController *)[[EXPERTconnect shared] startChat:chatSkill
                                                withDisplayName:@"AdHoc Chat"
                                                     withSurvey:NO];
        
        // Add our custom left bar button
        
        if(self.optNavButtons.on)
        {
            self.chatController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                                                    style:UIBarButtonItemStylePlain
                                                                                                   target:self
                                                                                                   action:@selector(backPushed:)];
            
            // Add our custom right bar button.
            self.chatController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"End Chat"
                                                                                                     style:UIBarButtonItemStylePlain
                                                                                                    target:self
                                                                                                    action:@selector(btnEndChat_Touch:)];
        }
               //[self.tableView reloadData]; // make it show continue chat
    }
    
    [self.btnStartChat setTitle:@"Return to Queue" forState:UIControlStateNormal];
    _chatActive = YES;
    
    // Push it onto our navigation stack (so back buttons will work)
    [self.navigationController pushViewController:self.chatController animated:YES];
}

// User pressed our custom back button
-(void)backPushed:(id)sender
{
    if( self.chatController.userInQueue ) {
        NSLog(@"Back pushed while in queue...");
    } else {
        NSLog(@"Back pushed while in chat...");
    }
    NSLog(@"Test Harness::Chat Nav Bar - Back button pushed.");
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)btnEndChat_Touch:(id)sender
{
    NSLog(@"Test Harness::Chat Nav Bar - End Chat button pushed.");
    
    UIAlertController *alert;
    UIAlertAction *defaultAction;
    
    if( _chatController.userInQueue )
    {
        alert = [UIAlertController alertControllerWithTitle:@"Exit Queue"
                                                    message:@"Are you sure you want to exit the queue? You will lose your place in line."
                                             preferredStyle:UIAlertControllerStyleAlert];
        
        defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action)
                         {
                             // We left the queue, so let's shut down chat (no "continue chat")
                             _chatActive = NO;
                             [_chatController endChatByUser];
                             [self.btnEndChat setEnabled:NO];
                             [self.btnStartChat setTitle:ECDLocalizedString(ECDLocalizedStartChatLabel, @"Start Chat") forState:UIControlStateNormal];
                             
                         }];
    }
    else
    {
        alert = [UIAlertController alertControllerWithTitle:@"End Chat"
                                                    message:@"Are you sure you want to end the chat?"
                                             preferredStyle:UIAlertControllerStyleAlert];
        
        defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action)
                         {
                             // This notification will inform the SDK to gracefully shut down the chat.
                             //[[NSNotificationCenter defaultCenter] postNotificationName:@"ECSEndChatNotification" object:nil];
                             
                             // This will directly inform the chatView to end the chat by user input.
                             [_chatController endChatByUser];
                             [self.btnEndChat setEnabled:NO];
                             [self.btnStartChat setTitle:ECDLocalizedString(ECDLocalizedStartChatLabel, @"Start Chat") forState:UIControlStateNormal];
                         }];
    }
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)optTimestamp_Change:(id)sender {
}

- (IBAction)optChatBubble_Change:(id)sender {
}

- (IBAction)optAvatarImages_Change:(id)sender {
}

- (IBAction)optNavButtons_Change:(id)sender {
}

#pragma mark Notifications

- (void)chatEnded:(NSNotification *)notification {
    
    NSLog(@"Test Harness::Chat Config - End chat notification received.");
    
    // If uncommented, this will hide chat when agent ends it.
    //[self.navigationController popToViewController:self animated:YES];
    _chatActive = NO;
    [self.btnEndChat setEnabled:NO];
    
    [self.btnStartChat setTitle:@"Start Chat" forState:UIControlStateNormal];
    NSLog(@"Chat ended!");
    //[self.tableView reloadData]; // show the start chat title
}

- (void)chatStarted:(NSNotification *)notification {
     _chatActive = YES;
     [self.btnEndChat setEnabled:YES];
     
     [self.btnStartChat setTitle:ECDLocalizedString(ECDLocalizedContinueChatLabel, @"Continue Chat")  forState:UIControlStateNormal];
     
}
- (void)chatMessageReceived:(NSNotification *)notification {
    
    // A chat text message.
    if ([notification.object isKindOfClass:[ECSChatTextMessage class]]) {
        ECSChatTextMessage *message = (ECSChatTextMessage *)notification.object;
        NSLog(@"Chat - incoming chat message: %@", message.body);
        
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
    
    // Add participant message.
    if ([notification.object isKindOfClass:[ECSChatAddParticipantMessage class]]) {
        ECSChatAddParticipantMessage *message = (ECSChatAddParticipantMessage *)notification.object;
        NSLog(@"Chat - Adding participant: %@ %@", message.firstName, message.lastName);
        
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
}

#pragma mark Picker View

-(void)setupPickerView {
    
    currentEnvironment = [[NSUserDefaults standardUserDefaults] objectForKey:@"environmentName"];
    if(!currentEnvironment) {
        currentEnvironment = @"IntDev";
    }
    
    if (![self addChatSkillsFromServer]) {
        //[self addChatSkillsHardcoded];
        NSLog(@"PROBLEM!");
    }
    
    // Attempt to load the selected skill for the selected environment
    currentChatSkill = [[NSUserDefaults standardUserDefaults]
                        stringForKey:[NSString stringWithFormat:@"%@_%@", currentEnvironment, lastChatSkillKey]];
    
    // Select the current skill in the flipper control.
    int currentRow = 0;
    rowToSelect = 0;
    if(currentChatSkill != nil)  {
        for(NSString* skill in chatSkillsArray) {
            if([skill isEqualToString:currentChatSkill])  {
                rowToSelect = currentRow;
                break;
            }
            currentRow++;
        }
    }
    
    [self getAgentsAvailableForExpertSkill:rowToSelect];
    
    [self.pickerChatSkill reloadAllComponents];
    [self.pickerChatSkill selectRow:rowToSelect inComponent:0 animated:NO];
    selectedRow = rowToSelect; // mas - fixed issue if user did not touch the slider would load skill at index 0. 
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    //[super pickerView:pickerView didSelectRow:row inComponent:component];
    [[NSUserDefaults standardUserDefaults] setObject:[chatSkillsArray objectAtIndex:row]
                                              forKey:[NSString stringWithFormat:@"%@_%@", currentEnvironment, lastChatSkillKey]];
    
    [self getAgentsAvailableForExpertSkill:(int)row];
    
    selectedRow = (int)row;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [chatSkillsArray count];
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    NSString *title;
    title=[chatSkillsArray objectAtIndex:row];
    return title;
}

-(void)getAgentsAvailableForExpertSkill:(int)index
{
    if( chatSkillsArray.count == 0 || chatSkillsArray.count < index) {
        NSLog(@"ChatConfigView - Attempted to load skill in array out of bounds.");
        return;
    }
    
    [[EXPERTconnect shared] getDetailsForExpertSkill:[chatSkillsArray objectAtIndex:index]
                                          completion:^(ECSSkillDetail *data, NSError *error)
     {
         NSMutableString *labelText = [[NSMutableString alloc] initWithString:@""];
         
         if(!error)
         {
             if(data.active && data.queueOpen && data.chatReady > 0)
             {
                 [labelText appendString:[NSString stringWithFormat:@"Estimated wait: %d seconds.", data.estWait]];
                 //[self.btnStartChat setEnabled:YES];
             }
             else
             {
                 // No agents available.
                 //[self.btnStartChat setEnabled:NO];
             }
             
             [self.lblAgentAvailability setText:[NSString stringWithFormat:@"Estimated wait is %d seconds. %d of %d agents ready. Queue is: %@. %d in queue now. Active=%d.",
                                                 data.estWait,
                                                 data.chatReady,
                                                 data.chatCapacity,
                                                 (data.queueOpen ? @"Open" : @"Closed"),
                                                 data.inQueue,
                                                 data.active]];
         } else {
             [labelText appendString:[NSString stringWithFormat:@"/experts/v1/skills ERROR: %@",error.description]];
         }
     }];
}

-(BOOL)addChatSkillsFromServer {
    
    NSArray *environmentConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"environmentConfig"];
    
    if (!environmentConfig) {
        return NO;
    }
    
    for( NSDictionary *envData in environmentConfig) {
        
        if (envData[@"name"] && [envData[@"name"] isEqualToString:currentEnvironment]) {
            
            if(envData[@"agent_skills"]) {
                
                chatSkillsArray = [NSMutableArray new];
                for ( NSString *skill in envData[@"agent_skills"] ) {
                    [chatSkillsArray addObject:skill];
                }
                [chatSkillsArray addObject:@"INVALID_SKILL"];
            }
        }
    }
    
    return YES;
}

#pragma mark - Keyboard Delegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return true;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField selectAll:self];
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
