/*
 * KeyAuthUI_native.mm
 * ══════════════════════════════════════════════════════════════
 * Native iOS UIKit dylib — UI ขึ้นอัตโนมัติเมื่อโหลด dylib
 *
 *  __attribute__((constructor))  ← รันก่อน main() ของแอป
 *  dispatch_async(main_queue)    ← รอ UIWindow พร้อม แล้ว present
 *
 * build:   bash build_native.sh
 * ══════════════════════════════════════════════════════════════
 */

#import "KeyAuthUI_native.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <time.h>

// ──────────────────────────────────────────────────────────────
// MARK: Random key
// ──────────────────────────────────────────────────────────────

static NSString *randomKey(int len) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ srand((unsigned)time(NULL)); });
    const char pool[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    int n = (int)(sizeof(pool) - 1);
    NSMutableString *s = [NSMutableString stringWithCapacity:len];
    for (int i = 0; i < len; i++) [s appendFormat:@"%c", pool[rand() % n]];
    return [s copy];
}

// ──────────────────────────────────────────────────────────────
// MARK: Colors
// ──────────────────────────────────────────────────────────────

#define RGBA(r,g,b,a) [UIColor colorWithRed:(r)/255.f green:(g)/255.f blue:(b)/255.f alpha:(a)]

static UIColor *cBG()        { return RGBA(22,  36,  62,  1.0f); }
static UIColor *cCard()      { return RGBA(14,  24,  45,  0.97f);}
static UIColor *cAccent()    { return RGBA(80, 180, 255,  1.0f); }
static UIColor *cSub()       { return RGBA(140,165,200,  1.0f); }
static UIColor *cInputBG()   { return RGBA(10,  20,  40,  1.0f); }
static UIColor *cBtnGray()   { return RGBA(68,  95, 120,  1.0f); }

// ──────────────────────────────────────────────────────────────
// MARK: Loading screen
// ──────────────────────────────────────────────────────────────

@interface _KALoadView : UIView
- (void)startWithDone:(dispatch_block_t)done;
@end

@implementation _KALoadView {
    UIProgressView  *_bar;
    UILabel         *_pctLbl;
    NSTimer         *_timer;
    float            _pct;
    dispatch_block_t _done;
}

- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    if (!self) return nil;
    self.backgroundColor = cBG();

    // ── gradient background layer ──────────────────────────
    CAGradientLayer *bgGrad = [CAGradientLayer layer];
    bgGrad.frame = f;
    bgGrad.colors = @[(__bridge id)RGBA(28,52,88,1).CGColor,
                      (__bridge id)RGBA(10,18,38,1).CGColor];
    bgGrad.startPoint = CGPointMake(0.3f, 0);
    bgGrad.endPoint   = CGPointMake(0.7f, 1);
    [self.layer insertSublayer:bgGrad atIndex:0];

    // ── card ──────────────────────────────────────────────
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor    = cCard();
    card.layer.cornerRadius = 28.f;
    card.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.10f].CGColor;
    card.layer.borderWidth  = 0.5f;
    [self addSubview:card];

    // ── logo ───────────────────────────────────────────────
    UIView *logoBox = [[UIView alloc] init];
    logoBox.translatesAutoresizingMaskIntoConstraints = NO;
    logoBox.layer.cornerRadius = 16.f;
    logoBox.clipsToBounds = YES;

    CAGradientLayer *lg = [CAGradientLayer layer];
    lg.frame = CGRectMake(0, 0, 60, 60);
    lg.colors = @[(__bridge id)RGBA(255,138,42,1).CGColor,
                  (__bridge id)RGBA(255, 70,130,1).CGColor,
                  (__bridge id)RGBA( 90,120,255,1).CGColor];
    lg.startPoint = CGPointMake(0,0); lg.endPoint = CGPointMake(1,1);
    [logoBox.layer addSublayer:lg];

    UILabel *ffLbl = [UILabel new];
    ffLbl.translatesAutoresizingMaskIntoConstraints = NO;
    ffLbl.text = @"FF";
    ffLbl.font = [UIFont boldSystemFontOfSize:22];
    ffLbl.textColor = UIColor.whiteColor;
    [logoBox addSubview:ffLbl];

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Free Fire MAX";
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textColor = UIColor.whiteColor;
    title.textAlignment = NSTextAlignmentCenter;

    UILabel *sub = [UILabel new];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    sub.text = @"กำลังตรวจสอบสิทธิ์...";
    sub.font = [UIFont systemFontOfSize:13];
    sub.textColor = cSub();
    sub.textAlignment = NSTextAlignmentCenter;

    _bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _bar.translatesAutoresizingMaskIntoConstraints = NO;
    _bar.progressTintColor = cAccent();
    _bar.trackTintColor    = RGBA(28,48,78,1);
    _bar.layer.cornerRadius = 4; _bar.clipsToBounds = YES;

    _pctLbl = [UILabel new];
    _pctLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _pctLbl.text = @"0%";
    _pctLbl.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightMedium];
    _pctLbl.textColor = cAccent();
    _pctLbl.textAlignment = NSTextAlignmentRight;

    [card addSubview:logoBox];
    [card addSubview:ffLbl];
    [card addSubview:title];
    [card addSubview:sub];
    [card addSubview:_bar];
    [card addSubview:_pctLbl];

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:300],

        [logoBox.topAnchor constraintEqualToAnchor:card.topAnchor constant:26],
        [logoBox.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [logoBox.widthAnchor constraintEqualToConstant:60],
        [logoBox.heightAnchor constraintEqualToConstant:60],

        [ffLbl.centerXAnchor constraintEqualToAnchor:logoBox.centerXAnchor],
        [ffLbl.centerYAnchor constraintEqualToAnchor:logoBox.centerYAnchor],

        [title.topAnchor constraintEqualToAnchor:logoBox.bottomAnchor constant:14],
        [title.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],

        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
        [sub.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],

        [_bar.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:20],
        [_bar.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [_bar.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [_bar.heightAnchor constraintEqualToConstant:6],

        [_pctLbl.topAnchor constraintEqualToAnchor:_bar.bottomAnchor constant:6],
        [_pctLbl.trailingAnchor constraintEqualToAnchor:_bar.trailingAnchor],
        [_pctLbl.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-22],
    ]];
    return self;
}

- (void)startWithDone:(dispatch_block_t)done {
    _done = [done copy]; _pct = 0;
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.034
                                             target:self
                                           selector:@selector(tick)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)tick {
    _pct += 2.f;
    if (_pct >= 100.f) {
        _pct = 100.f;
        [_timer invalidate]; _timer = nil;
        [_bar setProgress:1.f animated:YES];
        _pctLbl.text = @"100%";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.28*NSEC_PER_SEC)),
                       dispatch_get_main_queue(), _done);
        return;
    }
    [_bar setProgress:_pct/100.f animated:YES];
    _pctLbl.text = [NSString stringWithFormat:@"%.0f%%", _pct];
}
@end

// ──────────────────────────────────────────────────────────────
// MARK: Key input view
// ──────────────────────────────────────────────────────────────

@interface _KAKeyView : UIView
@property (nonatomic, copy) void (^onLogin)(NSString *);
@property (nonatomic, copy) void (^onWebsite)(void);
@end

@implementation _KAKeyView { UITextField *_tf; }

- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    if (!self) return nil;
    self.backgroundColor = cBG();

    CAGradientLayer *bgGrad = [CAGradientLayer layer];
    bgGrad.frame = f;
    bgGrad.colors = @[(__bridge id)RGBA(28,52,88,1).CGColor,
                      (__bridge id)RGBA(10,18,38,1).CGColor];
    bgGrad.startPoint = CGPointMake(0.3f,0); bgGrad.endPoint = CGPointMake(0.7f,1);
    [self.layer insertSublayer:bgGrad atIndex:0];

    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor    = cCard();
    card.layer.cornerRadius = 24;
    card.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.10f].CGColor;
    card.layer.borderWidth  = 0.5f;
    card.alpha = 0;
    card.transform = CGAffineTransformMakeScale(0.90f, 0.90f);
    [self addSubview:card];

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Free Fire MAX";
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textColor = cAccent();
    title.textAlignment = NSTextAlignmentCenter;

    UILabel *sub = [UILabel new];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    sub.text = @"請輸入您的金鑰";
    sub.font = [UIFont systemFontOfSize:13];
    sub.textColor = cSub();
    sub.textAlignment = NSTextAlignmentCenter;

    _tf = [UITextField new];
    _tf.translatesAutoresizingMaskIntoConstraints = NO;
    _tf.text = randomKey(18);
    _tf.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    _tf.textColor = UIColor.whiteColor;
    _tf.backgroundColor = cInputBG();
    _tf.layer.cornerRadius = 12;
    _tf.layer.borderColor  = RGBA(44,74,112,1).CGColor;
    _tf.layer.borderWidth  = 1;
    _tf.clipsToBounds = YES;
    UIView *lp = [[UIView alloc] initWithFrame:CGRectMake(0,0,14,0)];
    UIView *rp = [[UIView alloc] initWithFrame:CGRectMake(0,0,14,0)];
    _tf.leftView = lp; _tf.leftViewMode = UITextFieldViewModeAlways;
    _tf.rightView = rp; _tf.rightViewMode = UITextFieldViewModeAlways;
    _tf.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"金鑰" attributes:@{NSForegroundColorAttributeName:[UIColor grayColor]}];

    // Buttons
    UIButton *bWeb = [UIButton buttonWithType:UIButtonTypeCustom];
    bWeb.translatesAutoresizingMaskIntoConstraints = NO;
    [bWeb setTitle:@"網站" forState:UIControlStateNormal];
    bWeb.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    bWeb.backgroundColor = cBtnGray();
    bWeb.layer.cornerRadius = 22;
    [bWeb addTarget:self action:@selector(tapWeb) forControlEvents:UIControlEventTouchUpInside];

    UIButton *bLogin = [UIButton buttonWithType:UIButtonTypeCustom];
    bLogin.translatesAutoresizingMaskIntoConstraints = NO;
    [bLogin setTitle:@"登入" forState:UIControlStateNormal];
    bLogin.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    bLogin.backgroundColor = cAccent();
    bLogin.layer.cornerRadius = 22;
    [bLogin addTarget:self action:@selector(tapLogin) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[bWeb, bLogin]];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFillEqually;
    row.spacing = 12;

    [card addSubview:title];
    [card addSubview:sub];
    [card addSubview:_tf];
    [card addSubview:row];

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [card.topAnchor constraintEqualToAnchor:self.topAnchor constant:90],
        [card.widthAnchor constraintEqualToConstant:300],

        [title.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [title.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],

        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
        [sub.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],

        [_tf.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:16],
        [_tf.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [_tf.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [_tf.heightAnchor constraintEqualToConstant:46],

        [row.topAnchor constraintEqualToAnchor:_tf.bottomAnchor constant:14],
        [row.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [row.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [row.heightAnchor constraintEqualToConstant:44],
        [row.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20],
    ]];

    // pop-in
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.06*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.45
                              delay:0
             usingSpringWithDamping:0.70f
              initialSpringVelocity:0.4f
                            options:0
                         animations:^{
            card.alpha = 1; card.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
    return self;
}
- (void)tapLogin { if (self.onLogin) self.onLogin(_tf.text); }
- (void)tapWeb   { if (self.onWebsite) self.onWebsite(); }
@end

// ──────────────────────────────────────────────────────────────
// MARK: KAViewController (public)
// ──────────────────────────────────────────────────────────────

@implementation KAViewController {
    _KALoadView *_load;
    _KAKeyView  *_key;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = cBG();
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    self.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;

    _load = [[_KALoadView alloc] initWithFrame:self.view.bounds];
    _load.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_load];

    __weak __typeof(self) w = self;
    [_load startWithDone:^{ [w showKey]; }];
}

- (void)showKey {
    _key = [[_KAKeyView alloc] initWithFrame:self.view.bounds];
    _key.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _key.onLogin   = self.onLogin;
    _key.onWebsite = self.onWebsite;
    [self.view addSubview:_key];
    [UIView animateWithDuration:0.3 animations:^{ self->_load.alpha = 0; }
                     completion:^(BOOL _){ [self->_load removeFromSuperview]; }];
}

+ (void)presentOnWindow:(UIWindow *)window {
    UIViewController *root = window.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;
    KAViewController *vc = [KAViewController new];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    vc.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
    [root presentViewController:vc animated:YES completion:nil];
}

@end

// ──────────────────────────────────────────────────────────────
// MARK: Auto-present — รันอัตโนมัติเมื่อ dylib โหลด
// ──────────────────────────────────────────────────────────────

__attribute__((constructor))
static void KAAutoPresent(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        // รอให้ UIApplication + window พร้อม
        void (^__block attempt)(void) = nil;
        attempt = ^{
            UIWindow *win = nil;
            NSArray<UIScene*> *scenes = UIApplication.sharedApplication.connectedScenes.allObjects;
            for (UIScene *scene in scenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *ws = (UIWindowScene *)scene;
                    for (UIWindow *w in ws.windows) {
                        if (w.isKeyWindow) { win = w; break; }
                    }
                }
            }
            if (!win) {
                // ยังไม่พร้อม รอ 0.1 วิแล้วลองใหม่
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.1*NSEC_PER_SEC)),
                               dispatch_get_main_queue(), attempt);
                return;
            }
            [KAViewController presentOnWindow:win];
        };
        attempt();
    });
}
