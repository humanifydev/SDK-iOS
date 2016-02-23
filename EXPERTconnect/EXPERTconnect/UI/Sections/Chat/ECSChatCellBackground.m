//
//  ECSChatTableViewCell.m
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import "ECSChatCellBackground.h"

#import "ECSDynamicLabel.h"
#import "ECSInjector.h"
#import "UIImage+ECSBundle.h"
#import "ECSTheme.h"


@interface ECSChatCellBackground()


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarWidthConstraint;
@property (strong, nonatomic) NSLayoutConstraint *messageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarEdgeConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *messageBoxHorizontalAlignConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorContstraint;

@end

@implementation ECSChatCellBackground

- (void)awakeFromNib {
    // Initialization code
    [self setup];
    
    self.messageWidthConstraint = [NSLayoutConstraint constraintWithItem:self.messageContainerView attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.5 constant:0.0f];
    [self addConstraint:self.messageWidthConstraint];
	 
    [self configureConstraints];
}

- (void)setup
{
    [self setUserMessage:NO];
}

- (void)setUserMessage:(BOOL)userMessage
{
	 _userMessage = userMessage;
	 
	 ECSTheme *theme = [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
	 self.bubbleImage = [UIImage ecs_bundledImageNamed:@"ecs_chatbubble"];
	 CGPoint center = CGPointMake(self.bubbleImage.size.width / 2.0f, self.bubbleImage.size.height / 2.0f);
	 UIEdgeInsets capInsets = UIEdgeInsetsMake(center.y, center.x, center.y, center.x);
	 if (_userMessage)
	 {
		  if(theme.showChatBubbleTails == NO)
		  {
			   self.messageContainerView.backgroundColor = theme.userChatBackground;
		  }
		  else
		  {
			   self.bubbleImage = [self imageMaskedWithColor:theme.userChatBackground];
			   self.bubbleImage = [UIImage imageWithCGImage:self.bubbleImage.CGImage
													  scale:self.bubbleImage.scale
												orientation:UIImageOrientationDownMirrored];
			   self.bubbleImage =  [self stretchableImageFromImage:self.bubbleImage withCapInsets:capInsets];
			   [self.bubbleImageView setImage:self.bubbleImage];
		  }
	 }
	 else
	 {
		  if(theme.showChatBubbleTails == NO)
		  {
			   self.messageContainerView.backgroundColor = theme.agentChatBackground;
		  }
		  else
		  {
			   self.bubbleImage = [self imageMaskedWithColor:theme.agentChatBackground];
			   self.bubbleImage = [UIImage imageWithCGImage:self.bubbleImage.CGImage
													  scale:self.bubbleImage.scale
												orientation:UIImageOrientationDown];
			   self.bubbleImage =  [self stretchableImageFromImage:self.bubbleImage withCapInsets:capInsets];
			   [self.bubbleImageView setImage:self.bubbleImage];
		  }
	 }
	 
	 self.responseContainerView.backgroundColor = theme.userChatBackground;
	 
	 self.messageContainerView.layer.cornerRadius = theme.chatBubbleCornerRadius;
	 
	 [self configureConstraints];
}

- (UIImage *)imageMaskedWithColor:(UIColor *)maskColor
{
	 CGRect rect = CGRectMake(0, 0, self.bubbleImage.size.width, self.bubbleImage.size.height);
	 UIGraphicsBeginImageContext(rect.size);
	 CGContextRef context = UIGraphicsGetCurrentContext();
	 CGContextClipToMask(context, rect, self.bubbleImage.CGImage);
	 CGContextSetFillColorWithColor(context, maskColor.CGColor);
	 CGContextFillRect(context, rect);
	 UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	 UIGraphicsEndImageContext();
	 return newImage;
}

- (UIImage *)stretchableImageFromImage:(UIImage *)image withCapInsets:(UIEdgeInsets)capInsets
{
	 return [image resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
}

- (void)setShowAvatar:(BOOL)showAvatar
{
    _showAvatar = showAvatar;
	 
    if (_showAvatar)
    {
        [self.avatarImageView setAlpha:1.0f];
    }
    else
    {
        [self.avatarImageView setAlpha:0.0f];
    }
    
    [self configureConstraints];
}

- (void)setAvatarImageFromPath:(NSString *)theAvatar
{
    [self.avatarImageView setImageWithPath:theAvatar];
}

- (void)setAvatarImage:(UIImage *)theAvatar
{
    [self.avatarImageView setImage:theAvatar];
}

- (void)configureConstraints
{
    double margin = 10.0f;
    
    // This would make the chat bubble huge the edge instead of keep the same margins whether
    // an avatar photo was displayed or not.
    ECSTheme *theme = [[ECSInjector defaultInjector] objectForClass:[ECSTheme class]];
    self.avatarWidthConstraint.constant = (theme.showAvatarImages) ? 40.0f : 0.0f;
    
    [self removeConstraint:self.messageBoxHorizontalAlignConstraint];
    [self removeConstraint:self.avatarEdgeConstraint];
    
    if (self.isUserMessage)
    {
        // Remove leading. Add trailing.
        self.avatarEdgeConstraint = [NSLayoutConstraint constraintWithItem:self.avatarImageView
                                                                 attribute:NSLayoutAttributeTrailing
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeTrailing
                                                                multiplier:1.0f
                                                                  constant:-margin];
        
        self.messageBoxHorizontalAlignConstraint = [NSLayoutConstraint constraintWithItem:self.messageContainerView
                                                                                attribute:NSLayoutAttributeTrailing
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:self.avatarImageView
                                                                                attribute:NSLayoutAttributeLeading
                                                                               multiplier:1.0f
                                                                                 constant:-margin];

        //[self addConstraint:self.messageBoxHorizontalAlignConstraint];
    }
    else
    {
        self.avatarEdgeConstraint = [NSLayoutConstraint constraintWithItem:self.avatarImageView
                                                                 attribute:NSLayoutAttributeLeading
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeLeading
                                                                multiplier:1.0f
                                                                  constant:margin];
        
        self.messageBoxHorizontalAlignConstraint = [NSLayoutConstraint constraintWithItem:self.messageContainerView
                                                                                attribute:NSLayoutAttributeLeading
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:self.avatarImageView
                                                                                attribute:NSLayoutAttributeTrailing
                                                                               multiplier:1.0f
                                                                                 constant:margin];
        
        
    }
    [self addConstraint:self.avatarEdgeConstraint];
    [self addConstraint:self.messageBoxHorizontalAlignConstraint];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    if (self.responseContainerView.subviews.count)
    {
        self.separatorContstraint.constant = 5.0f;
    }
    else
    {
        self.separatorContstraint.constant = 0.0f;
    }
    
    [super layoutSubviews];
}
@end
