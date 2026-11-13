#import <UIKit/UIKit.h>

%hook UIColor

+ (UIColor *)dtk_colorWithHexString:(NSString *)string {
    if (string.length == 3) {
        // Expand 3-char hex to 6-char: #3F4 -> #33FF44
        NSString *expanded = [NSString stringWithFormat:@"%@%@%@%@%@%@",
            [string substringWithRange:NSMakeRange(0, 1)],
            [string substringWithRange:NSMakeRange(0, 1)],
            [string substringWithRange:NSMakeRange(1, 1)],
            [string substringWithRange:NSMakeRange(1, 1)],
            [string substringWithRange:NSMakeRange(2, 1)],
            [string substringWithRange:NSMakeRange(2, 1)]
        ];
        return %orig(expanded);
    }
    return %orig(string);
}

%end
