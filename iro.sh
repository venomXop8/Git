#!/bin/bash

# Telegram Ultimate Customizer
echo "🚀 Building irogram (Custom Branding + Red/White Chat Bubbles)..."

# Install dependencies
sudo apt update -y && sudo apt install -y wget unzip git openjdk-17-jdk imagemagick

# Setup Android SDK
wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip -q commandlinetools-linux-9477386_latest.zip
rm -f commandlinetools-linux-9477386_latest.zip
mkdir -p android-sdk/cmdline-tools/latest
mv cmdline-tools/* android-sdk/cmdline-tools/latest/
rm -rf cmdline-tools

# Environment variables
export ANDROID_SDK_ROOT="$PWD/android-sdk"
export ANDROID_NDK_HOME="$ANDROID_SDK_ROOT/ndk/25.2.9519653"
export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"

# Accept licenses
yes | sdkmanager --licenses > /dev/null
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2" "ndk;25.2.9519653"

# Clone Telegram source
git clone --depth=1 https://github.com/DrKLO/Telegram.git
cd Telegram

# ===== CUSTOMIZATIONS =====

# 1. Replace ALL UI instances of "Telegram" with "irogram" (except chat messages)
find . -type f \( -name "*.xml" -o -name "*.java" -o -name "*.kt" \) \
  -exec grep -l "Telegram" {} \; \
  | xargs sed -i 's/Telegram/irogram/g'

# 2. Revert changes in chat message strings
sed -i 's/irogram/Telegram/g' TMessagesProj/src/main/res/values*/strings.xml
sed -i 's/irogram/Telegram/g' TMessagesProj/src/main/java/org/telegram/messenger/*.java

# 3. App Icon (512x512)
if [ -f ../logo.png ]; then
  echo "🖼️ Replacing app icon..."
  convert ../logo.png -resize 512x512 ../logo_resized.png
  cp ../logo_resized.png TMessagesProj/src/main/res/mipmap-xxxhdpi/ic_launcher.png
  cp ../logo_resized.png TMessagesProj/src/main/res/mipmap-xxhdpi/ic_launcher.png
  cp ../logo_resized.png TMessagesProj/src/main/res/mipmap-xhdpi/ic_launcher.png
  cp ../logo_resized.png TMessagesProj/src/main/res/mipmap-hdpi/ic_launcher.png
  cp ../logo_resized.png TMessagesProj/src/main/res/mipmap-mdpi/ic_launcher.png
  rm ../logo_resized.png
fi

# 4. Launch Screen (1242x2688)
if [ -f ../launch.jpg ]; then
  echo "🌅 Replacing launch screen..."
  convert ../launch.jpg -resize 1242x2688^ -gravity center -extent 1242x2688 ../launch_resized.jpg
  cp ../launch_resized.jpg TMessagesProj/src/main/res/drawable/launch_screen.jpg
  rm ../launch_resized.jpg
fi

# 5. Red/White Chat Bubbles with Black Text
cat << 'EOT' > TMessagesProj/src/main/res/values/colors.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Branding -->
    <color name="actionBarDefault">#FF0000</color>
    <color name="actionBarDefaultWhite">#FFFFFFFF</color>
    
    <!-- Chat Bubbles -->
    <color name="chat_outBubble">#FFFF0000</color> <!-- Your messages: RED -->
    <color name="chat_inBubble">#FFFFFFFF</color> <!-- Their messages: WHITE -->
    <color name="chat_outBubbleText">#FF000000</color> <!-- BLACK text -->
    <color name="chat_inBubbleText">#FF000000</color> <!-- BLACK text -->
    
    <!-- Dark Theme -->
    <color name="windowBackgroundWhite">#FF121212</color>
    <color name="windowBackgroundGray">#FF1E1E1E</color>
</resources>
EOT

# 6. Force Dark Mode
sed -i '/<application/a \
    <meta-data android:name="android.force_dark" android:value="true" />' \
    TMessagesProj/src/main/AndroidManifest.xml

# Build
echo "🛠️ Building irogram APK (this may take 20-40 mins)..."
./gradlew assembleDebug

# Output
APK_PATH="$PWD/TMessagesProj/build/outputs/apk/debug/*.apk"
echo "✅ Build successful! Your customized irogram APK:"
echo "$APK_PATH"