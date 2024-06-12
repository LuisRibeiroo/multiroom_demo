#! /bin/bash

printf "\n--> Flutter clean\n"
flutter clean

printf "\n\n--> Flutter pub get\n"
flutter pub get

printf "\n\n--> Building Android APK"
flutter build apk --release

mv build/app/outputs/flutter-apk/app-release.apk bin/multiroom.apk
printf "\n\n--> Android build available at: bin/multiroom.apk\n"