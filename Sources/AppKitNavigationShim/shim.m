#if __has_include(<TargetConditionals.h>)
#include <TargetConditionals.h>

#if __has_include(<AppKit/AppKit.h>) && !TARGET_OS_MACCATALYST
@import ObjectiveC;
@import AppKit;
#import "shim.h"

@interface AppKitNavigationShim : NSObject

@end

@implementation AppKitNavigationShim

// NB: We must use Objective-C here to eagerly swizzle view controller code that is responsible
//     for state-driven presentation and dismissal of child features.

+ (void)load {
    method_exchangeImplementations(
        class_getInstanceMethod(NSViewController.class, @selector(viewDidAppear)),
        class_getInstanceMethod(NSViewController.class, @selector(AppKitNavigation_viewDidAppear))
        );
    method_exchangeImplementations(
        class_getInstanceMethod(NSViewController.class, @selector(viewDidDisappear)),
        class_getInstanceMethod(NSViewController.class, @selector(AppKitNavigation_viewDidDisappear))
        );
    method_exchangeImplementations(
        class_getInstanceMethod(NSViewController.class, @selector(dismissViewController:)),
        class_getInstanceMethod(NSViewController.class, @selector(AppKitNavigation_dismissViewController:))
        );
    method_exchangeImplementations(
        class_getInstanceMethod(NSSavePanel.class, NSSelectorFromString(@"setFinalURL:")),
        class_getInstanceMethod(NSSavePanel.class, @selector(AppKitNavigation_setFinalURL:))
        );
    method_exchangeImplementations(
        class_getInstanceMethod(NSSavePanel.class, NSSelectorFromString(@"setFinalURLs:")),
        class_getInstanceMethod(NSSavePanel.class, @selector(AppKitNavigation_setFinalURLs:))
        );
}

@end

@implementation NSSavePanel (AppKitNavigation)

- (void)setAppKitNavigation_onFinalURLs:(void (^)(NSArray<NSURL *> * _Nonnull))AppKitNavigation_onFinalURLs {
    objc_setAssociatedObject(self, @selector(AppKitNavigation_onFinalURLs), AppKitNavigation_onFinalURLs, OBJC_ASSOCIATION_COPY);
}

- (void (^)(NSArray<NSURL *> * _Nonnull))AppKitNavigation_onFinalURLs {
    return objc_getAssociatedObject(self, @selector(AppKitNavigation_onFinalURLs));
}

- (void)setAppKitNavigation_onFinalURL:(void (^)(NSURL * _Nullable))AppKitNavigation_onFinalURL {
    objc_setAssociatedObject(self, @selector(AppKitNavigation_onFinalURL), AppKitNavigation_onFinalURL, OBJC_ASSOCIATION_COPY);
}

- (void (^)(NSURL * _Nullable))AppKitNavigation_onFinalURL {
    return objc_getAssociatedObject(self, @selector(AppKitNavigation_onFinalURL));
}

- (void)AppKitNavigation_setFinalURL:(nullable NSURL *)url {
    [self AppKitNavigation_setFinalURL:url];
    if (self.AppKitNavigation_onFinalURL) {
        self.AppKitNavigation_onFinalURL(url);
    }
}

- (void)AppKitNavigation_setFinalURLs:(NSArray<NSURL *> *)urls {
    [self AppKitNavigation_setFinalURLs:urls];
    if (self.AppKitNavigation_onFinalURLs) {
        self.AppKitNavigation_onFinalURLs(urls);
    }
}

@end

static void *hasViewAppearedKey = &hasViewAppearedKey;
static void *onDismissKey = &onDismissKey;
static void *onViewAppearKey = &onViewAppearKey;

@implementation NSViewController (AppKitNavigation)

- (void)AppKitNavigation_viewDidAppear {
    [self AppKitNavigation_viewDidAppear];

    if (self.hasViewAppeared) {
        return;
    }

    self.hasViewAppeared = YES;

    for (void (^work)() in self.onViewAppear) {
        work();
    }

    self.onViewAppear = @[];
}

- (void)setBeingDismissed:(BOOL)beingDismissed {
    objc_setAssociatedObject(self, @selector(isBeingDismissed), @(beingDismissed), OBJC_ASSOCIATION_COPY);
}

- (BOOL)isBeingDismissed {
    return [objc_getAssociatedObject(self, @selector(isBeingDismissed)) boolValue];
}

- (void)AppKitNavigation_viewDidDisappear {
    [self AppKitNavigation_viewDidDisappear];

    if ((self.isBeingDismissed) && self.onDismiss != NULL) {
        self.onDismiss();
        self.onDismiss = nil;
        [self setBeingDismissed:NO];
    }
}

- (void)AppKitNavigation_dismissViewController:(NSViewController *)sender {
    [self AppKitNavigation_dismissViewController:sender];
    [self setBeingDismissed:YES];
}

- (BOOL)hasViewAppeared {
    return [objc_getAssociatedObject(self, hasViewAppearedKey) boolValue];
}

- (void)setHasViewAppeared:(BOOL)hasViewAppeared {
    objc_setAssociatedObject(
        self, hasViewAppearedKey, @(hasViewAppeared), OBJC_ASSOCIATION_COPY_NONATOMIC
        );
}

- (void (^)())onDismiss {
    return objc_getAssociatedObject(self, onDismissKey);
}

- (void)setOnDismiss:(void (^)())onDismiss {
    objc_setAssociatedObject(self, onDismissKey, [onDismiss copy], OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSMutableArray<void (^)()> *)onViewAppear {
    id onViewAppear = objc_getAssociatedObject(self, onViewAppearKey);

    return onViewAppear == nil ? @[] : onViewAppear;
}

- (void)setOnViewAppear:(NSMutableArray<void (^)()> *)onViewAppear {
    objc_setAssociatedObject(self, onViewAppearKey, onViewAppear, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
#endif /* if __has_include(<AppKit/AppKit.h>) && !TARGET_OS_MACCATALYST */
#endif /* if __has_include(<TargetConditionals.h>) */
