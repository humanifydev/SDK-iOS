//
//  ECSChatWaitView.m
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import "ECSChatWaitView.h"

#import "ECSTheme.h"
#import "ECSInjector.h"

@implementation ECSChatWaitView

- (void)awakeFromNib
{
    [super awakeFromNib];
    ECSTheme *theme = [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
    self.backgroundColor = theme.primaryBackgroundColor;
    
    self.titleLabel.font = theme.headlineFont;
    self.titleLabel.textColor = theme.primaryTextColor;
    self.subtitleLabel.font = theme.bodyFont;
    self.subtitleLabel.textColor = theme.primaryTextColor;
    
    [self.loadingView startAnimating];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startLoadingAnimation)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startLoadingAnimation)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

}

- (void) startLoadingAnimation {
    [self.loadingView startAnimating];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self]; 
}

@end
