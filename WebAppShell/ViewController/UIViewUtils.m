//
//  UIView+UIViewGeometry.m
//  YY2
//
//  Created by Kai on 13-8-6.
//  Copyright (c) 2013年 YY Inc. All rights reserved.
//

#import "UIViewUtils.h"

@implementation UIView (UIViewGeometryHelper)

- (CGFloat)width
{
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    
    self.frame = frame;
}

- (CGFloat)x
{
    return self.frame.origin.x;
}

- (void)setX:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat) y
{
    return self.frame.origin.y;
}

- (void)setY:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
 
}

- (CGFloat)bottom
{
    CGRect frame = self.frame;
    return frame.origin.y + frame.size.height;
}

- (void)setSize:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGSize)size
{
    return self.frame.size;
}

- (void)setOrigin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGPoint)origin
{
    return self.frame.origin;
}

@end


@implementation UIView (NSLayoutConstraintHelper)

- (void)fillSuperView
{
    if (self.superview) {
        if (self.translatesAutoresizingMaskIntoConstraints) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    }
}

- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr sibling:(UIView*) sibling constant:(CGFloat)c
{
    NSLayoutConstraint* ret = nil;
    if (self.superview) {
        if (self.translatesAutoresizingMaskIntoConstraints) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
        ret = [NSLayoutConstraint constraintWithItem:self attribute:attr relatedBy:NSLayoutRelationEqual toItem:sibling attribute:attr multiplier:1.0 constant:c];
        if (ret) {
            [self.superview addConstraint:ret];
        }
    }
    return ret;
}

- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr1 sibling:(UIView*)sibling attribute:(NSLayoutAttribute)attr2 constant:(CGFloat)c
{
    NSLayoutConstraint* ret = nil;
    if (self.superview && sibling) {
        if (self.translatesAutoresizingMaskIntoConstraints) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
        ret = [NSLayoutConstraint constraintWithItem:self attribute:attr1 relatedBy:NSLayoutRelationEqual toItem:sibling attribute:attr2 multiplier:1.0 constant:c];
        if (ret) {
            [self.superview addConstraint:ret];
        }
    }
    return ret;
}

- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr constant:(CGFloat)c
{
    NSLayoutConstraint* ret = nil;
    if (self.superview) {
        if (self.translatesAutoresizingMaskIntoConstraints) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
        ret = [NSLayoutConstraint constraintWithItem:self attribute:attr relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:attr multiplier:1.0 constant:c];
        if (ret) {
            [self.superview addConstraint:ret];
        }
    }
    return ret;
}

- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr multiplier:(CGFloat)m constant:(CGFloat)c
{
    NSLayoutConstraint* ret = nil;
    if (self.superview) {
        if (self.translatesAutoresizingMaskIntoConstraints) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
        ret = [NSLayoutConstraint constraintWithItem:self attribute:attr relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:attr multiplier:m constant:c];
        if (ret) {
            [self.superview addConstraint:ret];
        }
    }
    return ret;
}

- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr1 sibling:(UIView*) sibling attribute:(NSLayoutAttribute)attr2 multiplier:(CGFloat)m constant:(CGFloat)c
{
    NSLayoutConstraint* ret = nil;
    if (self.superview && sibling) {
        if (self.translatesAutoresizingMaskIntoConstraints) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
        ret = [NSLayoutConstraint constraintWithItem:self attribute:attr1 relatedBy:NSLayoutRelationEqual toItem:sibling attribute:attr2 multiplier:m constant:c];
        if (ret) {
            [self.superview addConstraint:ret];
        }
    }
    return ret;
}

- (NSLayoutConstraint*)addWidthConstraint:(CGFloat)c
{
    NSLayoutConstraint* ret = nil;
    if (self.superview) {
        if (self.translatesAutoresizingMaskIntoConstraints) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
        ret = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:c];
        if (ret) {
            [self.superview addConstraint:ret];
        }
    }
    return ret;
}

- (NSLayoutConstraint*)addHeightConstraint:(CGFloat)c
{
    NSLayoutConstraint* ret = nil;
    if (self.superview) {
        if (self.translatesAutoresizingMaskIntoConstraints) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
        }
        ret = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:c];
        if (ret) {
            [self.superview addConstraint:ret];
        }
    }
    return ret;
}
@end

@implementation UIScrollView (UIEdgeInsetHelper)

- (CGFloat)contentTop {
    return self.contentInset.top;
}

- (void)setContentTop:(CGFloat)contentTop {
    UIEdgeInsets insets = self.contentInset;
    insets.top = contentTop;
    self.contentInset = insets;
}

- (CGFloat)contentLeft {
    return self.contentInset.left;
}

- (void)setContentLeft:(CGFloat)contentLeft  {
    UIEdgeInsets insets = self.contentInset;
    insets.left = contentLeft;
    self.contentInset = insets;
}

- (CGFloat)contentBottom {
    return self.contentInset.bottom;
}

- (void)setContentBottom:(CGFloat)contentBottom {
    UIEdgeInsets insets = self.contentInset;
    insets.bottom = contentBottom;
    self.contentInset = insets;
}

- (CGFloat)contentRight {
    return self.contentInset.right;
}

- (void)setContentRight:(CGFloat)contentRight {
    UIEdgeInsets insets = self.contentInset;
    insets.right = contentRight;
    self.contentInset = insets;
}

@end
