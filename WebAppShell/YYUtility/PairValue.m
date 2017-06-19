//
//  PairValue.m
//  OnePiece
//
//  Created by huangshuqing on 23/5/2017.
//  Copyright © 2017 YY. All rights reserved.
//

#import "PairValue.h"

PairValue* MakePairValue(id first, id second) {
    PairValue* r = [PairValue new];
    r.first = first;
    r.second = second;
    return r;
}

@implementation PairValue

@end
