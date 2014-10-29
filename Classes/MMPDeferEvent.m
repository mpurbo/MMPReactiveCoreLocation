//
//  MMPDeferEvent.m
//
//  The MIT License (MIT)
//  Copyright (c) 2014 Mamad Purbo, purbo.org
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MMPDeferEvent.h"

@interface MMPDeferEvent()

@property(assign, nonatomic) CLLocationDistance untilTraveledDistance;
@property(assign, nonatomic) NSTimeInterval timeout;
@property(assign, nonatomic) MMPDeferEventType type;

@end

@implementation MMPDeferEvent

+ (instancetype)allowDeferredLocationUpdatesUntilTraveled:(CLLocationDistance)distance
                                                  timeout:(NSTimeInterval)timeout
{
    MMPDeferEvent *ret = [MMPDeferEvent new];
    ret.type = MMPDeferEventTypeAllow;
    ret.untilTraveledDistance = distance;
    ret.timeout = timeout;
    return ret;
}

+ (instancetype)disallowDeferredLocationUpdates
{
    MMPDeferEvent *ret = [MMPDeferEvent new];
    ret.type = MMPDeferEventTypeDisallow;
    return ret;
}

@end
