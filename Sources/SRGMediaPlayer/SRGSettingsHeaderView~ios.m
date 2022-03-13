//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSettingsHeaderView.h"

static void commonInit(SRGSettingsHeaderView *self);

@interface SRGSettingsHeaderView ()

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UILabel *titleLabel;

@end

@implementation SRGSettingsHeaderView

#pragma mark Class methods

+ (CGFloat)height
{
    return 50.f;
}

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Getters and setters

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.titleLabel.text = title.uppercaseString;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    self.imageView.image = image;
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.title;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitHeader;
}

#pragma mark Overrides

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    self.imageView.tintColor = tintColor;
    self.titleLabel.textColor = tintColor;
}

@end

static void commonInit(SRGSettingsHeaderView *self)
{
    // Create a full height view to force the contentView height
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:backgroundView];
    
    [NSLayoutConstraint activateConstraints:@[
        [backgroundView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:0.f],
        [backgroundView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:0.f],
        [backgroundView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0.f],
        [backgroundView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:0.f],
        [backgroundView.heightAnchor constraintEqualToConstant:SRGSettingsHeaderView.height]
    ]];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:imageView];
    self.imageView = imageView;
    
    NSLayoutConstraint *leadingAnchorConstraint = nil;
    if (@available(iOS 13, *)) {
        leadingAnchorConstraint = [imageView.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor];
    }
    else {
        leadingAnchorConstraint = [imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.f];
    }
    
    [NSLayoutConstraint activateConstraints:@[
        leadingAnchorConstraint,
        [imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4.f],
        [imageView.widthAnchor constraintEqualToConstant:25.f],
        [imageView.heightAnchor constraintEqualToConstant:25.f]
    ]];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    
    NSLayoutConstraint *trailingAnchorConstraint = nil;
    if (@available(iOS 13, *)) {
        trailingAnchorConstraint = [titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor];
    }
    else {
        trailingAnchorConstraint = [titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.f];
    }
    
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.leadingAnchor constraintEqualToAnchor:imageView.trailingAnchor constant:6.f],
        trailingAnchorConstraint,
        [titleLabel.centerYAnchor constraintEqualToAnchor:imageView.centerYAnchor]
    ]];
}
