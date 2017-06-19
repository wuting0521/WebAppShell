//
//  PairValue.h
//  OnePiece
//
//  Created by huangshuqing on 23/5/2017.
//  Copyright © 2017 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PairValue : NSObject

@property (nonatomic) id first;
@property (nonatomic) id second;

@end

extern PairValue* MakePairValue(id first, id second);
