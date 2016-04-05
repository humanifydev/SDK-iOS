//
//  ECSSelectExpertViewController.m
//  EXPERTconnect
//
//  Created by Mohammad Abdurraafay on 18/06/15.
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import "ECSSelectExpertViewController.h"
#import "ECSFeaturedTableViewCell.h"
#import "ECSSelectExpertsResponse.h"

#import "ECSSelectExpertTableViewCell.h"

#import "ECSCafeXController.h"
#import "ECSRootViewController+Navigation.h"
#import "ECSTheme.h"
#import "ECSInjector.h"
#import "ECSDynamicLabel.h"
#import "ECSCircleImageView.h"
#import "ECSVideoChatActionType.h"
#import "ECSChatActionType.h"
#import "ECSCafeXVideoViewController.h"
#import "UIViewController+ECSNibLoading.h"

static NSString *const ECSExpertCellId = @"ECSSelectExpertTableViewCell";

@interface ECSSelectExpertViewController () <UITableViewDataSource, UITableViewDelegate, ECSSelectExpertTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *experts;

@end

@implementation ECSSelectExpertViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.experts                = self.actionType.configuration[@"experts"];
    self.tableView.delegate     = self;
    self.tableView.dataSource   = self;
    
    // Apply themes
    ECSTheme *theme = [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
	 
    self.view.backgroundColor = theme.primaryBackgroundColor;
	 
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.tableView.sectionFooterHeight = 0.0f;
    
    self.navigationItem.title = self.actionType.displayName;
    
    UINib *featuredNib = [UINib nibWithNibName:[[ECSSelectExpertTableViewCell class] description]
                                        bundle:[NSBundle bundleForClass:[ECSSelectExpertTableViewCell class]]];
    
    [self.tableView registerNib:featuredNib forCellReuseIdentifier:ECSExpertCellId];
    
    // Try to load experts if none are currently loaded.
	 

    if(self.experts == nil) {
        
        __weak typeof(self) weakSelf = self;
		 [weakSelf setLoadingIndicatorVisible:YES];
        ECSURLSessionManager *urlSession = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
        
        // Attempt to fetch list of available experts from server
        [urlSession getExpertsWithInteractionItems:nil
                                        completion:^(NSArray *expertArray, NSError *error) {
                                            
            [weakSelf setLoadingIndicatorVisible:NO];
                                            
            if (!error) {
                
                // Reload the table with new data from response
                weakSelf.experts = expertArray;
                [weakSelf.tableView reloadData];
                
            } else {
                
                // Show a message to the user.
                [weakSelf showMessageForError:error];
            }
        }];
        
    }
	 
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.experts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	 NSDictionary *expert = [self.experts objectAtIndex:indexPath.row];
	 ECSSelectExpertTableViewCell *featuredCell = [tableView dequeueReusableCellWithIdentifier:ECSExpertCellId];
	 [featuredCell setSelectExpertCellDelegate:self];
	 [featuredCell.profileImage setImageWithPath:expert[@"pictureURL"]];
	 
	 featuredCell.firstLineView.hidden = YES;
	 featuredCell.regionView.hidden = NO;
	 NSLog(@"%@",self.actionType.type);
	 [featuredCell configureCellForActionType:self.actionType.type withExpert:expert];
	 
	 if(!([expert objectForKey:@"fullName"] == (id)[NSNull null]))[featuredCell.name setText:expert[@"fullName"]];
	 if(!([expert objectForKey:@"region"] == (id)[NSNull null]))[featuredCell.region setText:expert[@"region"]];
	 if(!([expert objectForKey:@"expertise"] == (id)[NSNull null]))[featuredCell.expertiese setText:expert[@"expertise"]];
	 if(!([expert objectForKey:@"interests"] == (id)[NSNull null]))[featuredCell.interests setText:[expert[@"interests"] componentsJoinedByString:@", "]];
	 
	 if([expert objectForKey:@"region"] || [expert objectForKey:@"interests"])
	 {
		  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		  {
			   featuredCell.firstLineView.hidden = NO;
			   [featuredCell configureConstraints];
		  }
	 }
	 else{
		  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		  {
			   featuredCell.regionView.hidden = YES;
			   [featuredCell configureConstraints];
		  }
		  else
		  {
			   featuredCell.regionHeightConstraints.constant = 0.0f;
			   featuredCell.regionView.hidden = YES;
		  }
	 }
	 
	 return featuredCell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *expert = self.experts[indexPath.row];
    ECSChatActionType *actionType = [ECSChatActionType new];
    actionType.actionId = self.actionType.actionId;
    actionType.agentId = expert[@"agentId"];
    actionType.agentSkill = expert[@"agentSkill"];
    
     //DEBUG CODE: This only occurs if there's an "override" agent set in the Debug menu. Safe to leave.
    
    NSString *agent = [[NSUserDefaults standardUserDefaults] stringForKey:@"agent_key"];
    if (agent.length > 0) {
        NSString *skill = [NSString stringWithFormat:@"Calls for %@", agent];
        actionType.agentSkill =  skill;
        actionType.agentId = agent;
    }
    
    [self handleAction:actionType];
}

- (BOOL)handleAction:(ECSActionType *)actionType
{
    BOOL handled = [super handleAction:actionType];
    
    if (!handled)
    {
        [self ecs_navigateToViewControllerForActionType:actionType];
        handled = YES;
    }
    
    return handled;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath; {
	 
	 CGFloat height = 0.0f;
	 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		  height = 200;
	 }
	 else
	 {
		  NSDictionary *expert = [self.experts objectAtIndex:indexPath.row];
		  
		  if([expert objectForKey:@"region"] || [expert objectForKey:@"interests"])
		  {
			   height = 250;
		  }
		  else{
			   height = 200;
		  }
		  
	 }
	 return height;
}



- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    //ECSNavigationSection *navSection = self.navigationContext.sections[section];
    CGFloat height = 1.0f;
    /*if (!IsNullOrEmpty(self.actionType.displayName))
    {
        height = 42.0f;
    }*/

    return height;
}

#pragma mark - ECSSelectExpertTableViewCellDelegate Methods

- (void)didSelectChatButton:(id)sender forExpert:(NSDictionary *)expert {
    ECSChatActionType *actionType = [ECSChatActionType new];
    actionType.actionId = self.actionType.actionId;
    actionType.agentId = expert[@"agentId"];
    actionType.agentSkill = expert[@"agentSkill"];
    
    /**
     DEBUG CODE: BEGINS
     **/
    NSString *agent = [[NSUserDefaults standardUserDefaults] stringForKey:@"agent_key"];
    if (agent.length > 0) {
        NSString *skill = [NSString stringWithFormat:@"Calls for %@", agent];
        actionType.agentSkill =  skill;
        actionType.agentId = agent;
    }
    /**
     DEBUG CODE: ENDS
     **/
    
    //    [EXPERTconnect shared]//
    [self handleAction:actionType];
}

- (void)didSelectVideoChatButton:(id)sender forExpert:(NSDictionary *)expert {
    ECSCafeXController *cafeXController = [[ECSInjector defaultInjector] objectForClass:[ECSCafeXController class]];
    
    // Do a login if there's no session:
    if (![cafeXController hasCafeXSession]) {
        [cafeXController setupCafeXSession];
    }
    
    ECSVideoChatActionType *actionType = [ECSVideoChatActionType new];
    actionType.actionId = self.actionType.actionId;
    actionType.agentId = expert[@"agentId"];
    actionType.agentSkill = expert[@"agentSkill"];
    actionType.cafexmode = @"videoauto"; // @"voicecapable,videocapable,cobrowsecapable";
    actionType.cafextarget = [cafeXController cafeXUsername];
    
    // DEBUG CODE: This only occurs if there's an "override" agent set in the
    // Debug menu. Safe to leave.
    
    NSString *agent = [[NSUserDefaults standardUserDefaults] stringForKey:@"agent_key"];
    if (agent.length > 0) {
        NSString *skill = [NSString stringWithFormat:@"Calls for %@", agent];
        actionType.agentSkill =  skill;
        actionType.agentId = agent;
    }
    
    [self handleAction:actionType];
}

- (void)didSelectVoiceChatButton:(id)sender forExpert:(NSDictionary *)expert {
    ECSCafeXController *cafeXController = [[ECSInjector defaultInjector] objectForClass:[ECSCafeXController class]];
    
    // Do a login if there's no session:
    if (![cafeXController hasCafeXSession]) {
        [cafeXController setupCafeXSession];
    }
    
    ECSVideoChatActionType *actionType = [ECSVideoChatActionType new];
    actionType.actionId = self.actionType.actionId;
    actionType.agentId = expert[@"agentId"];
    actionType.agentSkill = expert[@"agentSkill"];
    actionType.cafexmode = @"voiceauto"; // @"voicecapable,videocapable,cobrowsecapable";
    actionType.cafextarget = [cafeXController cafeXUsername];
    
    // DEBUG CODE: This only occurs if there's an "override" agent set in the
    // Debug menu. Safe to leave.
    
    NSString *agent = [[NSUserDefaults standardUserDefaults] stringForKey:@"agent_key"];
    if (agent.length > 0) {
        NSString *skill = [NSString stringWithFormat:@"Calls for %@", agent];
        actionType.agentSkill =  skill;
        actionType.agentId = agent;
    }
    
    [self handleAction:actionType];
}

- (void)didSelectCallBackButton:(id)sender forExpert:(NSDictionary *)expert {
      ECSRootViewController *voiceCallbackvc =  (ECSRootViewController *)[[EXPERTconnect shared] startVoiceCallback:@"communications" withDisplayName:@"Callback"];
        voiceCallbackvc.workflowDelegate = self.workflowDelegate;
      [self.navigationController pushViewController:voiceCallbackvc animated:YES];
}

@end
