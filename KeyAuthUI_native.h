#ifndef KEYAUTH_NATIVE_H
#define KEYAUTH_NATIVE_H

/*
 * KeyAuthUI_native.dylib
 * ──────────────────────────────────────────────────────────
 * inject เข้าแอปแล้ว UI ขึ้นอัตโนมัติ ไม่ต้องเรียกอะไรเพิ่ม
 * ใช้ __attribute__((constructor)) — รันทันทีตอน dylib โหลด
 *
 * build:  bash build_native.sh
 * inject: สอด libKeyAuthUI_native.dylib เข้า .ipa / jailbreak tweak
 * ──────────────────────────────────────────────────────────
 */

#import <UIKit/UIKit.h>

/* ViewController สำหรับกรณีต้องการแสดงด้วยตนเอง */
@interface KAViewController : UIViewController
@property (nonatomic, copy) void (^onLogin)(NSString *key);
@property (nonatomic, copy) void (^onWebsite)(void);
+ (void)presentOnWindow:(UIWindow *)window;
@end

#endif
