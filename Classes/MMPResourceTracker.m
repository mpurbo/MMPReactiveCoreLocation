//
//  MMPResourceTracker.m
//  Pods
//
//  Created by Purbo Mohamad on 1/24/15.
//
//

#import "MMPResourceTracker.h"

// =============================================================================
// MMPTrackableResource
// =============================================================================

@interface MMPTrackableResource : NSObject

@property (nonatomic, readwrite, strong) id<MMPResource> resource;
@property (nonatomic, readwrite, assign) NSUInteger refCount;

@end

@implementation MMPTrackableResource

- (id)initWithResource:(id<MMPResource>)resource {
    self = [super init];
    if (self) {
        self.resource = resource;
        _refCount = 1;
    }
    return self;
}

- (void)inc {
    _refCount++;
}

- (void)dec {
    _refCount--;
}

@end

// =============================================================================
// MMPResourceTracker
// =============================================================================

@interface MMPResourceTracker()

@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic, strong) id queue;

@end

@implementation MMPResourceTracker

+ (instancetype)instance {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initSingletonInstance];
    });
    return shared;
}

- (instancetype)initSingletonInstance {
    self = [super init];
    if (self) {
        self.cache = [NSMutableDictionary new];
        // TODO: should investigate whether to use SERIAL queue instead
        self.queue = dispatch_queue_create("org.purbo.MMPResourceTracker.queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (id<MMPResource>)getResourceWithHelper:(id<MMPResourceLifecycleHelper>)resourceHelper {
    
    NSString *key = [resourceHelper key];
    if (!key) {
        return nil;
    }
    
    __block id<MMPResource> resource = nil;
    
    dispatch_sync(_queue, ^{
        MMPTrackableResource *trackableResource = [_cache objectForKey:key];
        if (trackableResource) {
            resource = trackableResource.resource;
        }
    });
    
    return resource;
}

- (id<MMPResource>)retainResourceWithHelper:(id<MMPResourceLifecycleHelper>)resourceHelper {
    
    NSString *key = [resourceHelper key];
    if (!key) {
        return nil;
    }
    
    __block id<MMPResource> resource;
    
    dispatch_barrier_sync(_queue, ^{
        MMPTrackableResource *trackableResource = [_cache objectForKey:key];
        if (trackableResource) {
            // resource available, increment reference count
            [trackableResource inc];
            resource = trackableResource.resource;
        } else {
            // no resource, create first
            resource = [resourceHelper createResource];
            trackableResource = [[MMPTrackableResource alloc] initWithResource:resource];
            [_cache setObject:trackableResource forKey:key];
        }
    });
    
    return resource;
}

- (NSUInteger)releaseResourceWithHelper:(id<MMPResourceLifecycleHelper>)resourceHelper {
    
    NSString *key = [resourceHelper key];
    if (!key) {
        return 0;
    }
    
    __block NSUInteger refCount = 0;
    
    dispatch_barrier_sync(_queue, ^{
        MMPTrackableResource *trackableResource = [_cache objectForKey:key];
        if (trackableResource) {
            [trackableResource dec];
            if (trackableResource.refCount <= 0) {
                [_cache removeObjectForKey:key];
                [resourceHelper releaseResource:trackableResource.resource];
            } else {
                refCount = trackableResource.refCount;
            }
        } else {
            // not supposed to happen, ignore
        }
    });
    
    return refCount;
}

/*
- (id)cacheObjectForKey:(id)key {    
    if (!key) return nil;
    
    __block id obj;
    dispatch_sync(_queue, ^{
        obj = [_cache objectForKey:key];
    });
    return obj;
}

- (void)setCacheObject:(id)obj
                forKey:(id)key {
    if (!obj || !key) return;
    
    dispatch_barrier_async(_queue, ^{
        [_cache setObject: obj forKey: key];
    });
}

- (void)removeCacheObjectForKey:(id)key {
    if (!key) return;
    
    dispatch_barrier_async(_queue, ^{
        [_cache removeObjectForKey:key];
    });
}
*/

@end
