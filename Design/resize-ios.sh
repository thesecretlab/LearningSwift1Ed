ORIGINAL_ICON=$1

function size {
    convert "$ORIGINAL_ICON" -resize $1 "Icon-$2.png"
}

size 1024 1024
size 512 512

size 76 76
size 152 76@2x

size 72 72
size 144 72@2x
size 216 72@3x

size 120 60@2x
size 180 60@3x

size 57 57
size 114 57@2x
size 171 57@3x

size 50 50
size 100 50@2x

size 40 40
size 80 40@2x
size 120 40@3x

size 29 29
size 58 29@2x
size 87 29@3x

size 120 120

size 167 83.5@2x





