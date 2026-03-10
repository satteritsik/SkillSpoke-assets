#!/usr/bin/env bash
# generate-app-assets.sh — Generates all application images from brand source SVGs.
#
# Sources:  v1/svg/
# Outputs:  app/web/    — favicons, PWA, OG/social, logos
#           app/mobile/ — iOS 26 asset catalogs (dark+tinted icons, SVG image
#                         sets, color sets), Android mipmaps, shared splash
#           app/macos/  — .icns, tray icons
#
# iOS target: iOS 26 / Xcode 17+ (single 1024x1024 app icon with dark+tinted
#             variants, SVG single-scale image sets, no legacy size matrix).
#
# Prerequisites:
#   brew install imagemagick optipng    # optipng is optional
#   rsvg-convert, sips, iconutil        # already on macOS
#
# Usage:
#   cd /path/to/SkillSpoke-assets
#   bash generate-app-assets.sh
#
# Idempotent — safe to rerun after asset updates.

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SVG_DIR="$SCRIPT_DIR/v1/svg"
OUT_ROOT="$SCRIPT_DIR/app"

# Brand colors (used for canvas backgrounds in social/OG images)
COLOR_DARK="#1e1a14"
COLOR_LIGHT="#f5f0e8"
COLOR_GOLD="#e8b031"

# ---------------------------------------------------------------------------
# Tool checks
# ---------------------------------------------------------------------------
missing=()
for cmd in rsvg-convert sips iconutil; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ! command -v magick >/dev/null 2>&1; then
    missing+=("magick (brew install imagemagick)")
fi
if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: Missing required tools: ${missing[*]}"
    exit 1
fi

HAS_OPTIPNG=false
command -v optipng >/dev/null 2>&1 && HAS_OPTIPNG=true

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
svg2png() {
    # svg2png <input.svg> <output.png> <width> [height]
    # Pass width=0 or width="" to size by height only.
    local src="$1" dst="$2" w="$3" h="${4:-}"
    mkdir -p "$(dirname "$dst")"
    if [ -n "$w" ] && [ "$w" != "0" ] && [ -n "$h" ]; then
        rsvg-convert -w "$w" -h "$h" "$src" -o "$dst"
    elif [ -n "$h" ]; then
        rsvg-convert -h "$h" "$src" -o "$dst"
    else
        rsvg-convert -w "$w" "$src" -o "$dst"
    fi
    optimize "$dst"
}

optimize() {
    if $HAS_OPTIPNG; then
        optipng -quiet -o2 "$1" 2>/dev/null || true
    fi
}

copy_svg() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
}

log() {
    echo "  $1"
}

# ---------------------------------------------------------------------------
# Source SVG mapping
# ---------------------------------------------------------------------------
# Square assets (512x512 viewBox)
MARK_DARK="$SVG_DIR/mark-ondark.svg"
MARK_LIGHT="$SVG_DIR/mark-onlight.svg"
SQUARE_DARK="$SVG_DIR/squarelogo-ondark.svg"
SQUARE_LIGHT="$SVG_DIR/squarelogo-onlight.svg"

# Wide assets (combomarks)
COMBO_DARK="$SVG_DIR/combomark-ondark.svg"
COMBO_LIGHT="$SVG_DIR/combomark-onlight.svg"
COMBO_TAG_DARK="$SVG_DIR/combomark-tagline1-ondark.svg"
COMBO_TAG_LIGHT="$SVG_DIR/combomark-tagline1-onlight.svg"
COMBO_TAG_GOLD="$SVG_DIR/combomark-tagline-gold1-ondark.svg"

# Lettermarks
LETTER_DARK="$SVG_DIR/lettermark-ondark.svg"
LETTER_TAG_DARK="$SVG_DIR/lettermark-tagline-ondark.svg"
LETTER_TAG_LIGHT="$SVG_DIR/lettermark-tagline-onlight.svg"

# Taglines
TAGLINE_DARK="$SVG_DIR/tagline-ondark.svg"
TAGLINE_GOLD="$SVG_DIR/tagline-gold-ondark.svg"

# Verify sources exist
for f in "$MARK_DARK" "$MARK_LIGHT" "$SQUARE_DARK" "$SQUARE_LIGHT" \
         "$COMBO_DARK" "$COMBO_LIGHT" "$COMBO_TAG_DARK" "$COMBO_TAG_LIGHT"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Missing source SVG: $f"
        exit 1
    fi
done

echo "=== SkillSpoke App Asset Generator ==="
echo "Source: $SVG_DIR"
echo "Output: $OUT_ROOT"
echo ""

# ===================================================================
# WEB ASSETS
# ===================================================================
WEB="$OUT_ROOT/web"
echo "[web] Generating web assets..."

# --- Favicons ---
FAV="$WEB/favicon"
mkdir -p "$FAV"
log "favicons"
copy_svg "$MARK_LIGHT" "$FAV/favicon.svg"
for size in 16 32 48 96 180; do
    svg2png "$MARK_LIGHT" "$FAV/favicon-${size}x${size}.png" "$size"
done

# apple-touch-icon (180x180, uses squarelogo on light for filled appearance)
svg2png "$SQUARE_LIGHT" "$WEB/apple-touch-icon.png" 180

# favicon.ico (multi-resolution: 16, 32, 48)
log "favicon.ico"
magick "$FAV/favicon-16x16.png" "$FAV/favicon-32x32.png" "$FAV/favicon-48x48.png" "$FAV/favicon.ico"

# --- PWA manifest icons ---
PWA="$WEB/pwa"
mkdir -p "$PWA"
log "PWA icons"
for size in 72 96 128 144 152 192 384 512; do
    svg2png "$SQUARE_LIGHT" "$PWA/icon-${size}x${size}.png" "$size"
done

# Maskable icons (with safe-zone padding — 10% inset on each side)
log "PWA maskable icons"
for size in 192 512; do
    # Render mark at 80% of target, then center on colored canvas
    inner=$(( size * 80 / 100 ))
    rsvg-convert -w "$inner" "$MARK_LIGHT" -o "$PWA/_tmp_inner.png"
    magick -size "${size}x${size}" "xc:$COLOR_LIGHT" \
        "$PWA/_tmp_inner.png" -gravity center -composite \
        "$PWA/maskable-icon-${size}x${size}.png"
    optimize "$PWA/maskable-icon-${size}x${size}.png"
    rm -f "$PWA/_tmp_inner.png"
done

# --- Logo SVGs and PNGs for web use ---
WLOGO="$WEB/logo"
mkdir -p "$WLOGO"
log "web logos"

# SVG copies
copy_svg "$MARK_DARK" "$WLOGO/mark-ondark.svg"
copy_svg "$MARK_LIGHT" "$WLOGO/mark-onlight.svg"
copy_svg "$COMBO_DARK" "$WLOGO/combomark-ondark.svg"
copy_svg "$COMBO_LIGHT" "$WLOGO/combomark-onlight.svg"
copy_svg "$COMBO_TAG_DARK" "$WLOGO/combomark-tagline-ondark.svg"
copy_svg "$COMBO_TAG_LIGHT" "$WLOGO/combomark-tagline-onlight.svg"
copy_svg "$COMBO_TAG_GOLD" "$WLOGO/combomark-tagline-gold-ondark.svg"
copy_svg "$LETTER_TAG_DARK" "$WLOGO/lettermark-tagline-ondark.svg"
copy_svg "$LETTER_TAG_LIGHT" "$WLOGO/lettermark-tagline-onlight.svg"
copy_svg "$TAGLINE_DARK" "$WLOGO/tagline-ondark.svg"
copy_svg "$TAGLINE_GOLD" "$WLOGO/tagline-gold-ondark.svg"

# PNG rasters at common web sizes
# Mark (square): 32, 48, 64, 128, 256, 512
for size in 32 48 64 128 256 512; do
    svg2png "$MARK_DARK" "$WLOGO/mark-ondark-${size}.png" "$size"
    svg2png "$MARK_LIGHT" "$WLOGO/mark-onlight-${size}.png" "$size"
done

# Combomark (wide): height-based renders for header use
for h in 32 40 48 64; do
    svg2png "$COMBO_DARK" "$WLOGO/combomark-ondark-h${h}.png" "" "$h"
    svg2png "$COMBO_LIGHT" "$WLOGO/combomark-onlight-h${h}.png" "" "$h"
done

# --- Open Graph and Social sharing images ---
SOCIAL="$WEB/social"
mkdir -p "$SOCIAL"
log "OG and social images"

generate_social_image() {
    # generate_social_image <width> <height> <bg_color> <logo_svg> <logo_height> <output>
    local w="$1" h="$2" bg="$3" logo="$4" lh="$5" out="$6"
    rsvg-convert -h "$lh" "$logo" -o "$SOCIAL/_tmp_logo.png"
    magick -size "${w}x${h}" "xc:${bg}" \
        "$SOCIAL/_tmp_logo.png" -gravity center -composite \
        "$out"
    optimize "$out"
    rm -f "$SOCIAL/_tmp_logo.png"
}

# OG images (1200x630)
generate_social_image 1200 630 "$COLOR_DARK" "$COMBO_TAG_GOLD" 80 "$SOCIAL/og-image-dark.png"
generate_social_image 1200 630 "$COLOR_LIGHT" "$COMBO_TAG_LIGHT" 80 "$SOCIAL/og-image-light.png"

# Twitter cards (1200x600)
generate_social_image 1200 600 "$COLOR_DARK" "$COMBO_TAG_GOLD" 72 "$SOCIAL/twitter-card-dark.png"
generate_social_image 1200 600 "$COLOR_LIGHT" "$COMBO_TAG_LIGHT" 72 "$SOCIAL/twitter-card-light.png"

# LinkedIn company logo (300x300)
generate_social_image 300 300 "$COLOR_DARK" "$MARK_DARK" 180 "$SOCIAL/linkedin-company.png"

# LinkedIn banner (1584x396)
generate_social_image 1584 396 "$COLOR_DARK" "$COMBO_TAG_GOLD" 64 "$SOCIAL/linkedin-banner.png"

# Facebook cover (820x312)
generate_social_image 820 312 "$COLOR_DARK" "$COMBO_TAG_GOLD" 56 "$SOCIAL/facebook-cover.png"

# Instagram profile (320x320)
generate_social_image 320 320 "$COLOR_DARK" "$MARK_DARK" 200 "$SOCIAL/instagram-profile.png"

# --- Email assets ---
EMAIL="$WEB/email"
mkdir -p "$EMAIL"
log "email assets"
# Header logo (600px wide max, transparent)
svg2png "$COMBO_LIGHT" "$EMAIL/email-header-logo-onlight.png" 600
svg2png "$COMBO_DARK" "$EMAIL/email-header-logo-ondark.png" 600
# Footer logo (200px wide)
svg2png "$COMBO_LIGHT" "$EMAIL/email-footer-logo-onlight.png" 200
svg2png "$COMBO_DARK" "$EMAIL/email-footer-logo-ondark.png" 200

# ===================================================================
# MOBILE ASSETS — iOS (targeting iOS 26 / Xcode 17+)
# ===================================================================
IOS="$OUT_ROOT/mobile/ios"
echo ""
echo "[mobile/ios] Generating iOS 26 assets..."

# --- App Icon (single 1024x1024 + dark + tinted variants) ---
APPICON="$IOS/AppIcon.appiconset"
mkdir -p "$APPICON"
log "AppIcon.appiconset (light + dark + tinted)"

# Light variant (default) — squarelogo on light background
svg2png "$SQUARE_LIGHT" "$APPICON/AppIcon.png" 1024

# Dark variant — squarelogo on dark background
svg2png "$SQUARE_DARK" "$APPICON/AppIcon-dark.png" 1024

# Tinted variant — grayscale version the system colorizes per user preference
rsvg-convert -w 1024 "$SQUARE_LIGHT" -o "$APPICON/_tmp_tinted.png"
magick "$APPICON/_tmp_tinted.png" -colorspace Gray "$APPICON/AppIcon-tinted.png"
optimize "$APPICON/AppIcon-tinted.png"
rm -f "$APPICON/_tmp_tinted.png"

cat > "$APPICON/Contents.json" <<'CONTENTS_JSON'
{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    },
    {
      "appearances": [
        { "appearance": "luminosity", "value": "dark" }
      ],
      "filename": "AppIcon-dark.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    },
    {
      "appearances": [
        { "appearance": "luminosity", "value": "tinted" }
      ],
      "filename": "AppIcon-tinted.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": { "author": "generate-app-assets.sh", "version": 1 }
}
CONTENTS_JSON

# --- iOS logo image sets (SVG single-scale for vector assets) ---
IOS_IMG="$IOS/Images.xcassets"
mkdir -p "$IOS_IMG"
log "SVG image sets (single-scale)"

generate_ios_svg_imageset() {
    # generate_ios_svg_imageset <name> <svg_source> <output_dir>
    # Uses SVG directly — Xcode renders at any scale without rasterization.
    local name="$1" svg="$2" dir="$3"
    local setdir="$dir/${name}.imageset"
    mkdir -p "$setdir"

    cp "$svg" "$setdir/${name}.svg"

    cat > "$setdir/Contents.json" <<EOF
{
  "images": [
    {
      "filename": "${name}.svg",
      "idiom": "universal"
    }
  ],
  "info": { "author": "generate-app-assets.sh", "version": 1 },
  "properties": {
    "preserves-vector-representation": true
  }
}
EOF
}

# Mark (icon only) — vector, scales to any size
generate_ios_svg_imageset "mark-ondark" "$MARK_DARK" "$IOS_IMG"
generate_ios_svg_imageset "mark-onlight" "$MARK_LIGHT" "$IOS_IMG"

# Square logo
generate_ios_svg_imageset "squarelogo-ondark" "$SQUARE_DARK" "$IOS_IMG"
generate_ios_svg_imageset "squarelogo-onlight" "$SQUARE_LIGHT" "$IOS_IMG"

# Combomarks (wide)
generate_ios_svg_imageset "combomark-ondark" "$COMBO_DARK" "$IOS_IMG"
generate_ios_svg_imageset "combomark-onlight" "$COMBO_LIGHT" "$IOS_IMG"
generate_ios_svg_imageset "combomark-tagline-ondark" "$COMBO_TAG_DARK" "$IOS_IMG"
generate_ios_svg_imageset "combomark-tagline-onlight" "$COMBO_TAG_LIGHT" "$IOS_IMG"
generate_ios_svg_imageset "combomark-tagline-gold-ondark" "$COMBO_TAG_GOLD" "$IOS_IMG"

# Lettermarks
generate_ios_svg_imageset "lettermark-tagline-ondark" "$LETTER_TAG_DARK" "$IOS_IMG"
generate_ios_svg_imageset "lettermark-tagline-onlight" "$LETTER_TAG_LIGHT" "$IOS_IMG"

# Taglines
generate_ios_svg_imageset "tagline-ondark" "$TAGLINE_DARK" "$IOS_IMG"
generate_ios_svg_imageset "tagline-gold-ondark" "$TAGLINE_GOLD" "$IOS_IMG"

# --- Color sets for brand colors in Xcode ---
log "color sets"

generate_ios_colorset() {
    # generate_ios_colorset <name> <hex_light> <hex_dark> <output_dir>
    local name="$1" hex_light="$2" hex_dark="$3" dir="$4"
    local setdir="$dir/${name}.colorset"
    mkdir -p "$setdir"

    # Parse hex to float components
    hex_to_rgb() {
        local hex="${1#\#}"
        printf '%.4f' "$(echo "scale=4; $((16#${hex:0:2})) / 255" | bc)"
        printf ' '
        printf '%.4f' "$(echo "scale=4; $((16#${hex:2:2})) / 255" | bc)"
        printf ' '
        printf '%.4f' "$(echo "scale=4; $((16#${hex:4:2})) / 255" | bc)"
    }

    local light_rgb dark_rgb
    light_rgb=($(hex_to_rgb "$hex_light"))
    dark_rgb=($(hex_to_rgb "$hex_dark"))

    cat > "$setdir/Contents.json" <<EOF
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "${light_rgb[0]}",
          "green": "${light_rgb[1]}",
          "blue": "${light_rgb[2]}",
          "alpha": "1.0000"
        }
      },
      "idiom": "universal"
    },
    {
      "appearances": [
        { "appearance": "luminosity", "value": "dark" }
      ],
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "${dark_rgb[0]}",
          "green": "${dark_rgb[1]}",
          "blue": "${dark_rgb[2]}",
          "alpha": "1.0000"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": { "author": "generate-app-assets.sh", "version": 1 }
}
EOF
}

generate_ios_colorset "BrandBackground" "$COLOR_LIGHT" "$COLOR_DARK" "$IOS_IMG"
generate_ios_colorset "BrandForeground" "$COLOR_DARK" "$COLOR_LIGHT" "$IOS_IMG"
generate_ios_colorset "BrandAccent" "$COLOR_GOLD" "$COLOR_GOLD" "$IOS_IMG"
generate_ios_colorset "BrandMuted" "#a8a0b0" "#a8a0b0" "$IOS_IMG"

# Top-level Contents.json for Images.xcassets
cat > "$IOS_IMG/Contents.json" <<'EOF'
{
  "info": { "author": "generate-app-assets.sh", "version": 1 }
}
EOF

# Note: Launch screen uses a LaunchScreen.storyboard (not image assets).
# The storyboard references image sets from Images.xcassets above.
# No dedicated LaunchScreen image set is needed for iOS 26.

# ===================================================================
# MOBILE ASSETS — Android
# ===================================================================
ANDROID="$OUT_ROOT/mobile/android"
echo ""
echo "[mobile/android] Generating Android assets..."

# --- Launcher icons (mipmap) ---
log "mipmap launcher icons"
declare -A ANDROID_DPI=(
    ["mdpi"]="48"
    ["hdpi"]="72"
    ["xhdpi"]="96"
    ["xxhdpi"]="144"
    ["xxxhdpi"]="192"
)

for dpi in "${!ANDROID_DPI[@]}"; do
    px="${ANDROID_DPI[$dpi]}"
    dir="$ANDROID/mipmap-${dpi}"
    mkdir -p "$dir"
    svg2png "$SQUARE_LIGHT" "$dir/ic_launcher.png" "$px"
    # Round variant (same source, applied at build with Android shape mask)
    svg2png "$SQUARE_LIGHT" "$dir/ic_launcher_round.png" "$px"
done

# Play Store icon (512x512)
svg2png "$SQUARE_LIGHT" "$ANDROID/playstore-icon.png" 512

# --- Adaptive icon foreground/background ---
ADAPTIVE="$ANDROID/mipmap-xxxhdpi"
log "adaptive icon layers"
# Foreground: mark only, centered on transparent 432x432 (108dp * 4)
# The safe zone is the inner 66% (72dp of 108dp), so icon at ~288px centered in 432
rsvg-convert -w 288 "$MARK_LIGHT" -o "$ADAPTIVE/_tmp_fg.png"
magick -size 432x432 xc:none \
    "$ADAPTIVE/_tmp_fg.png" -gravity center -composite \
    "$ADAPTIVE/ic_launcher_foreground.png"
optimize "$ADAPTIVE/ic_launcher_foreground.png"
rm -f "$ADAPTIVE/_tmp_fg.png"

# Background: solid brand color
magick -size 432x432 "xc:$COLOR_LIGHT" "$ADAPTIVE/ic_launcher_background.png"

# --- Android drawable logos ---
DRAWABLE="$ANDROID/drawable"
mkdir -p "$DRAWABLE"
log "drawable logos"

# Logo variants for in-app use — render at xxxhdpi (4x), let Android downscale
svg2png "$MARK_DARK" "$DRAWABLE/mark_ondark.png" 192
svg2png "$MARK_LIGHT" "$DRAWABLE/mark_onlight.png" 192
rsvg-convert -h 128 "$COMBO_DARK" -o "$DRAWABLE/combomark_ondark.png"
optimize "$DRAWABLE/combomark_ondark.png"
rsvg-convert -h 128 "$COMBO_LIGHT" -o "$DRAWABLE/combomark_onlight.png"
optimize "$DRAWABLE/combomark_onlight.png"

# ===================================================================
# MOBILE ASSETS — Shared (React Native / Expo)
# ===================================================================
SHARED="$OUT_ROOT/mobile/shared"
mkdir -p "$SHARED"
echo ""
echo "[mobile/shared] Generating shared mobile assets..."
log "splash and notification icons"

# Splash image (centered mark on branded background)
for variant in light dark; do
    if [ "$variant" = "light" ]; then
        bg="$COLOR_LIGHT"; mark="$MARK_LIGHT"
    else
        bg="$COLOR_DARK"; mark="$MARK_DARK"
    fi
    rsvg-convert -w 300 "$mark" -o "$SHARED/_tmp_splash_mark.png"
    # Common splash: 1284x2778 (iPhone 14 Pro Max @3x)
    magick -size 1284x2778 "xc:${bg}" \
        "$SHARED/_tmp_splash_mark.png" -gravity center -composite \
        "$SHARED/splash-${variant}.png"
    optimize "$SHARED/splash-${variant}.png"
    rm -f "$SHARED/_tmp_splash_mark.png"
done

# Notification icon (Android: 96x96 white silhouette; iOS uses app icon)
svg2png "$MARK_LIGHT" "$SHARED/notification-icon.png" 96

# ===================================================================
# macOS ASSETS
# ===================================================================
MACOS="$OUT_ROOT/macos"
mkdir -p "$MACOS"
echo ""
echo "[macos] Generating macOS assets..."

# --- .icns via iconutil ---
ICONSET="$MACOS/AppIcon.iconset"
mkdir -p "$ICONSET"
log "AppIcon.icns"

declare -A ICNS_SIZES=(
    ["icon_16x16.png"]="16"
    ["icon_16x16@2x.png"]="32"
    ["icon_32x32.png"]="32"
    ["icon_32x32@2x.png"]="64"
    ["icon_128x128.png"]="128"
    ["icon_128x128@2x.png"]="256"
    ["icon_256x256.png"]="256"
    ["icon_256x256@2x.png"]="512"
    ["icon_512x512.png"]="512"
    ["icon_512x512@2x.png"]="1024"
)

for filename in "${!ICNS_SIZES[@]}"; do
    px="${ICNS_SIZES[$filename]}"
    svg2png "$SQUARE_LIGHT" "$ICONSET/$filename" "$px"
done

iconutil -c icns "$ICONSET" -o "$MACOS/AppIcon.icns"
rm -rf "$ICONSET"

# --- Tray / menu bar icon ---
TRAY="$MACOS/tray"
mkdir -p "$TRAY"
log "tray icons"
svg2png "$MARK_LIGHT" "$TRAY/tray-icon.png" 22
svg2png "$MARK_LIGHT" "$TRAY/tray-icon@2x.png" 44

# ===================================================================
# Summary
# ===================================================================
echo ""
echo "=== Generation complete ==="
total=$(find "$OUT_ROOT" -type f -not -name '_tmp*' -not -name '.DS_Store' | wc -l | tr -d ' ')
echo "Total files: $total"
echo ""
echo "Output tree:"
find "$OUT_ROOT" -type d | sort | while read -r d; do
    count=$(find "$d" -maxdepth 1 -type f -not -name '.DS_Store' | wc -l | tr -d ' ')
    if [ "$count" -gt 0 ]; then
        rel="${d#$SCRIPT_DIR/}"
        echo "  $rel/ ($count files)"
    fi
done
