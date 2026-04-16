/*
 * Tweak.xm  —  FreeFireKeyAuth
 * inject เข้า Free Fire MAX แล้วแสดง Key Auth UI อัตโนมัติ
 */

#import <UIKit/UIKit.h>
#import "KeyAuthUI_native.h"

// ── Hook UIApplication ดักตอน app เปิดเสร็จ ──────────────────
%hook UIApplication

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // หา key window แล้ว present UI
            UIWindow *win = nil;
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                        if (w.isKeyWindow) { win = w; break; }
                    }
                }
            }
            if (win) [KAViewController presentOnWindow:win];
        });
    });
}

%end
