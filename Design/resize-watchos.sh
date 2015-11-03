ORIGINAL_ICON=$1

function size {
    convert "$ORIGINAL_ICON" -resize $1 "Icon-$2.png"
}

size 48 AppleWatch-Notification-38mm
size 55 AppleWatch-Notification-42mm

size 58 AppleWatch-Companion-Settings@2x
size 87 AppleWatch-Companion-Settings@3x

size 80 AppleWatch-HomeScreen-All-LongLook-38mm
size 88 AppleWatch-LongLook-42mm

size 172 AppleWatch-ShortLook-38mm
size 196 AppleWatch-ShortLook-42mm




