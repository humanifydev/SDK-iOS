//
//  ECDAdHocVoiceCallbackPicker.m
//  EXPERTconnectDemo
//
//  Created by Ken Washington on 8/6/15.
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ECDAdHocVoiceCallbackPicker.h"

@implementation ECDAdHocVoiceCallbackPicker

static NSString *const lastVoiceCallbackKey = @"lastVoiceCallbackKey";

NSMutableArray *chatSkillsArray;
NSString *currentEnvironment;
NSString *currentChatSkill;
int selectedRow;
int rowToSelect;

-(void)setup {
    
    currentEnvironment = [[NSUserDefaults standardUserDefaults] objectForKey:@"environmentName"];
    if(!currentEnvironment) {
        currentEnvironment = @"IntDev";
    }
    
    if (![self addChatSkillsFromServer]) {
        [self addChatSkillsHardcoded];
    }
    
    // Attempt to load the selected organization for the selected environment
    currentChatSkill = [[NSUserDefaults standardUserDefaults]
                        stringForKey:[NSString stringWithFormat:@"%@_%@", currentEnvironment, lastVoiceCallbackKey]];
    
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
    
    [super setup:chatSkillsArray withSelection:rowToSelect];
    
    double width = (UIScreen.mainScreen.traitCollection.horizontalSizeClass == 1 ? 200.0f : 320.0f);
    [self setFrame: CGRectMake(0.0f, 0.0f, width, 180.0f)];
	 
    [self performSelector:@selector(getAgentsForLastSelected) withObject:nil afterDelay:0.5];
}

-(void)getAgentsForLastSelected {
	 //int rowToSelect = [[[NSUserDefaults standardUserDefaults] objectForKey:lastSkillSelected] intValue];
	 [self getAgentsAvailableForSkill:rowToSelect];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    [super pickerView:pickerView didSelectRow:row inComponent:component];
    [[NSUserDefaults standardUserDefaults] setObject:[chatSkillsArray objectAtIndex:row]
                                              forKey:[NSString stringWithFormat:@"%@_%@", currentEnvironment, lastVoiceCallbackKey]];
	 [self getAgentsAvailableForSkill:(int)row];
}

-(void)getAgentsAvailableForSkill:(int)index
{
	 [[EXPERTconnect shared] getDetailsForExpertSkill:[chatSkillsArray objectAtIndex:index]
									 completion:^(ECSSkillDetail *data, NSError *error)
	  {
          if(!error)
          {
              [[NSNotificationCenter defaultCenter] postNotificationName:@"CallbackSkillAgentInfoUpdated"
                                                                  object:data
                                                                userInfo:nil];
          }
          else
          {
              NSLog(@"Error fetching agent availability for callback skill.");
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

-(void)addChatSkillsHardcoded {
    chatSkillsArray = [NSMutableArray new];
    
    [chatSkillsArray addObject:@"CE_Mobile_Chat"];
    [chatSkillsArray addObject:@"Finance"];
    [chatSkillsArray addObject:@"Sales"];
    [chatSkillsArray addObject:@"webnav"];
    [chatSkillsArray addObject:@"wgenQs"];
    [chatSkillsArray addObject:@"wmtvte"];
    [chatSkillsArray addObject:@"wppv"];
    [chatSkillsArray addObject:@"wtrack"];
    [chatSkillsArray addObject:@"Calls for ken_mktwebextc"];
    [chatSkillsArray addObject:@"Calls for nathan_mktwebextc"];
    [chatSkillsArray addObject:@"Calls for ken_horizon"];
    [chatSkillsArray addObject:@"Calls for nathan_horizon"];
    [chatSkillsArray addObject:@"Calls for samantha_horizon"];
    [chatSkillsArray addObject:@"Calls for chris_horizon"];
}

@end