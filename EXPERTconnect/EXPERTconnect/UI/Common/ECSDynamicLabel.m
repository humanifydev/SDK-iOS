//
//  ECSDynamicLabel.m
//  EXPERTconnect
//
//  Copyright (c) 2015 Humanify, Inc. All rights reserved.
//

#import "ECSDynamicLabel.h"

@interface ECSDynamicLabel()

@property (strong, nonatomic) UIFont *baseFont;

@end

static NSArray *fontSizes;
static dispatch_once_t onceToken;
static CGFloat defaultFontIndex;

@implementation ECSDynamicLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self setup];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup
{
    self.baseFont = self.font;
    
    dispatch_once(&onceToken, ^{
        fontSizes = @[
                      UIContentSizeCategoryExtraSmall,
                      UIContentSizeCategorySmall,
                      UIContentSizeCategoryMedium,
                      UIContentSizeCategoryLarge,
                      UIContentSizeCategoryExtraLarge,
                      UIContentSizeCategoryExtraExtraLarge,
                      UIContentSizeCategoryExtraExtraExtraLarge,
                      UIContentSizeCategoryAccessibilityMedium,
                      UIContentSizeCategoryAccessibilityLarge,
                      UIContentSizeCategoryAccessibilityExtraLarge,
                      UIContentSizeCategoryAccessibilityExtraExtraLarge,
                      UIContentSizeCategoryAccessibilityExtraExtraExtraLarge
                      ];
        defaultFontIndex = 3;
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentSizeChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)setFont:(UIFont *)font
{
    self.baseFont = font;
    
    NSInteger categoryIndex = [fontSizes indexOfObject:[[UIApplication sharedApplication] preferredContentSizeCategory]];
    if (categoryIndex < 0)
    {
        categoryIndex = defaultFontIndex;
    }
    
    CGFloat fontSize = self.baseFont.fontDescriptor.pointSize;
    
    
    fontSize = fontSize + ((categoryIndex - defaultFontIndex) * 2.0f);
    
    // Make minimum 12pt otherwise you really can't read it
    fontSize = MAX(fontSize, 12.0f);
    
    [super setFont:[UIFont fontWithDescriptor:self.baseFont.fontDescriptor size:fontSize]];
}

- (void)contentSizeChanged:(NSNotification*)notification
{
    self.font = self.baseFont;
}
@end
