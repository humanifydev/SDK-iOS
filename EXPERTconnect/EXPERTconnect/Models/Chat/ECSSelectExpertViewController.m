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

#import "ECSRootViewController+Navigation.h"
#import "ECSTheme.h"
#import "ECSInjector.h"
#import "ECSDynamicLabel.h"
#import "ECSCircleImageView.h"
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
    self.experts = self.actionType.configuration[@"experts"];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Apply themes
    ECSTheme *theme = [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
    self.view.backgroundColor = theme.primaryBackgroundColor;
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.tableView.sectionFooterHeight = 0.0f;
    
    self.navigationItem.title = self.actionType.displayName;
    
    UINib *featuredNib = [UINib nibWithNibName:[[ECSSelectExpertTableViewCell class] description]
                                        bundle:[NSBundle bundleForClass:[ECSSelectExpertTableViewCell class]]];
    [self.tableView registerNib:featuredNib forCellReuseIdentifier:ECSExpertCellId];
    
    if(self.experts == nil) {
        __weak typeof(self) weakSelf = self;
        
        ECSURLSessionManager *urlSession = [[ECSInjector defaultInjector] objectForClass:[ECSURLSessionManager class]];
        [urlSession getExpertsWithCompletion:^(ECSSelectExpertsResponse *response, NSError *error) {
            [weakSelf setLoadingIndicatorVisible:NO];
            if (!error)
            {
                weakSelf.experts = response.action.configuration[@"experts"];
                [weakSelf.tableView reloadData];
            }
            else
            {
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
    return self.experts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *expert = [self.experts objectAtIndex:indexPath.row];
    ECSSelectExpertTableViewCell *featuredCell = [tableView dequeueReusableCellWithIdentifier:ECSExpertCellId];
    [featuredCell setSelectExpertCellDelegate:self];
    [featuredCell.profileImage setImageWithPath:expert[@"pictureURL"]];
    [featuredCell.name setText:expert[@"fullName"]];
    [featuredCell.region setText:expert[@"region"]];
    [featuredCell.expertiese setText:expert[@"expertise"]];
    [featuredCell.interests setText:[expert[@"interests"] componentsJoinedByString:@", "]];
    [featuredCell configureCellForActionType:self.actionType.type];
    return featuredCell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *expert = self.experts[indexPath.row];
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
  //  [self handleAction:actionType];
    
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
    return 208.0;
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

- (void)chatPressed {
    NSDictionary *expert = self.experts[0];
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

- (void)videoPressed {
    ECSCafeXVideoViewController *cafeXVideoViewController = [ECSCafeXVideoViewController ecs_loadFromNib];
    [self.navigationController pushViewController:cafeXVideoViewController animated:YES];
}

- (void)callBackPressed {
      UIViewController *voiceCallbackvc =  [[EXPERTconnect shared] startVoiceCallback:@"shammiskill" withDisplayName:@"Chatting with test"];
      [self.navigationController pushViewController:voiceCallbackvc animated:YES];
}

- (void)actionPressed {
    if ([self.actionType.type isEqualToString:ECSActionTypeSelectExpertChat]) {
        [self chatPressed];
    } else if ([self.actionType.type isEqualToString:ECSActionTypeSelectExpertVideo]) {
        [self videoPressed];
    } else if ([self.actionType.type isEqualToString:ECSActionTypeSelectExpertVoiceCallback]) {
        [self callBackPressed];
    }
}


@end
