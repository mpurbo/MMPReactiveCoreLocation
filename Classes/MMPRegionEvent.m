//
//  MMPRegionEvent.m
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

#import "MMPRegionEvent.h"

@interface MMPRegionEvent()

@property(readwrite, nonatomic, assign) MMPRegionEventType type;
@property(readwrite, nonatomic, strong) CLRegion *region;
@property(readwrite, nonatomic, assign) CLRegionState state;
@property(readwrite, nonatomic, strong) NSArray *beacons;
@property(readwrite, nonatomic, strong) NSError *error;

@end

@implementation MMPRegionEvent

- (id)initWithType:(MMPRegionEventType)type forRegion:(CLRegion *)region
{
    if (self = [super init]) {
        self.type = type;
        self.region = region;
    }
    return self;
}

- (id)initWithType:(MMPRegionEventType)type state:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (self = [super init]) {
        self.type = type;
        self.state = state;
        self.region = region;
    }
    return self;
}

- (id)initWithType:(MMPRegionEventType)type error:(NSError *)error forRegion:(CLRegion *)region
{
    if (self = [super init]) {
        self.type = type;
        self.error = error;
        self.region = region;
    }
    return self;
}

- (id)initWithType:(MMPRegionEventType)type beacons:(NSArray *)beacons forRegion:(CLBeaconRegion *)region
{
    if (self = [super init]) {
        self.type = type;
        self.beacons = beacons;
        self.region = region;
    }
    return self;
}

@end
