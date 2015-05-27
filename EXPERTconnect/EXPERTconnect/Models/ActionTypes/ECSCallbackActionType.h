//
//  ECSCallbackActionType.h
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import <EXPERTconnect/EXPERTconnect.h>

@interface ECSCallbackActionType : ECSActionType <NSCopying>

@property (strong, nonatomic) NSString *agentSkill;
@property (strong, nonatomic) NSString *agentId;

@end
