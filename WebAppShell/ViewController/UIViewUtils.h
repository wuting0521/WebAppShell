//
//  UIView+UIViewGeometry.h
//  YY2
//
//  Created by Kai on 13-8-6.
//  Copyright (c) 2013年 YY Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (UIViewGeometryHelper)

@property(assign, nonatomic) CGFloat width;
@property(assign, nonatomic) CGFloat height;
@property(assign, nonatomic) CGFloat x;
@property(assign, nonatomic) CGFloat y;
@property(readonly, nonatomic) CGFloat bottom;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint origin;

@end

@interface UIView (NSLayoutConstraintHelper)

- (void)fillSuperView;
- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr constant:(CGFloat)c;
- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr multiplier:(CGFloat)m constant:(CGFloat)c;
- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr sibling:(UIView*) sibling constant:(CGFloat)c;
- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr1 sibling:(UIView*) sibling attribute:(NSLayoutAttribute)attr2 constant:(CGFloat)c;
- (NSLayoutConstraint*)addConstraint:(NSLayoutAttribute)attr1 sibling:(UIView*) sibling attribute:(NSLayoutAttribute)attr2 multiplier:(CGFloat)m constant:(CGFloat)c;

- (NSLayoutConstraint*)addWidthConstraint:(CGFloat)c;
- (NSLayoutConstraint*)addHeightConstraint:(CGFloat)c;

@end

@interface UIScrollView (UIEdgeInsetHelper)
@property (assign, nonatomic) CGFloat contentTop;
@property (assign, nonatomic) CGFloat contentLeft;
@property (assign, nonatomic) CGFloat contentBottom;
@property (assign, nonatomic) CGFloat contentRight;
@end
