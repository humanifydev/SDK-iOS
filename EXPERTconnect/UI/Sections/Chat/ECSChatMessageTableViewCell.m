//
//  ECSChatMessageTableViewCell.m
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import "ECSChatMessageTableViewCell.h"

#import "ECSChatCellBackground.h"
#import "ECSInjector.h"
#import "ECSTheme.h"

@implementation ECSChatMessageTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        ECSTheme *theme = [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
        
        self.messageLabel = [[ECSDynamicLabel alloc] initWithFrame:self.background.messageContainerView.frame];
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.background.messageContainerView addSubview:self.messageLabel];
        
        [self.messageLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.messageLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.messageLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        [self.background.messageContainerView addConstraints:[NSLayoutConstraint
                constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(%ld)-[label]-(%ld)-|",(long)theme.chatBubbleHorizMargins,(long)theme.chatBubbleHorizMargins]
                                    options:0
                                    metrics:nil
                           views:@{@"label": self.messageLabel}]];
        
        [self.background.messageContainerView addConstraints:[NSLayoutConstraint
                constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(%ld)-[label]-(%ld)-|",(long)theme.chatBubbleVertMargins,(long)theme.chatBubbleVertMargins]
                                    options:0
                                    metrics:nil
                                      views:@{@"label": self.messageLabel}]];
        
        self.messageLabel.font = theme.chatFont;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    ECSTheme *theme = [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
    
    // Max frame of a message is (up to) half the width of the window. Then, we subtract the margins. 
    self.messageLabel.preferredMaxLayoutWidth = (self.frame.size.width * 0.5f) - (2 * (long)theme.chatBubbleHorizMargins);
    [super layoutSubviews];
}

- (void)setUserMessage:(BOOL)userMessage
{
    [super setUserMessage:userMessage];
    
    ECSTheme *theme = [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
    
    if (self.isUserMessage)
    {
        self.messageLabel.textColor = theme.userChatTextColor;
    }
    else
    {
        self.messageLabel.textColor = theme.agentChatTextColor;
    }
}
@end
