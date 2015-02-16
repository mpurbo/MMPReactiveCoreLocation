//
//  MMPResourceTracker.h
//  Pods
//
//  Created by Purbo Mohamad on 1/24/15.
//
//

#import <Foundation/Foundation.h>

@protocol MMPResource<NSObject>
@end

@protocol MMPResourceLifecycleHelper<NSObject>

- (NSString *)key;
- (id<MMPResource>)createResource;
- (void)releaseResource:(id<MMPResource>)resource;

@end

/**
 *  Utility for thread-safe resource tracking.
 */
@interface MMPResourceTracker : NSObject

// clue for improper use (produces compile time error)
+ (instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
- (instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

/**
 *  Gets the singleton object of this class.
 *
 *  @return Singleton object of this class.
 */
+ (instancetype)instance;

- (id<MMPResource>)getResourceWithHelper:(id<MMPResourceLifecycleHelper>)resourceHelper;
- (id<MMPResource>)retainResourceWithHelper:(id<MMPResourceLifecycleHelper>)resourceHelper;
- (NSUInteger)releaseResourceWithHelper:(id<MMPResourceLifecycleHelper>)resourceHelper;

@end
