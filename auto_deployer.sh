printf "\nAUTO DEPLOYER 2026\n\n"


# Build unsigned APK with Gradle
# TODO Determine what inside Android Studio fixes the initial build
printf "\t[1/5] Assembling unsigned APK..\n"

./gradlew assemble >/dev/null


# Generate keystore Java file (if non-existent)

if ! [ -f auto_deployer-dependencies/quick-release-key.jks ]
then	
	printf "\t[2/5] Generating keystore file...\n"
	keytool -genkey -keystore auto_deployer-dependencies/quick-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias andrewc < auto_deployer-dependencies/signature_details.txt 2>/dev/null
else
	printf "\t[2/5] Existing keystore file located...\n" 
fi


# Symbolic links for zipalign and apksigner, releases folder too
# For ease of implementation, removed at end of script to avoid clutter

ln -s auto_deployer-dependencies/selected-Android-SDK-build-tools-37.0.0/zipalign ./zipalign
ln -s auto_deployer-dependencies/selected-Android-SDK-build-tools-37.0.0/apksigner ./apksigner
ln -s app/build/outputs/apk/release/ ./


# Align APK files (required before signing APK file)

printf "\t[3/5] Aligning uncompressed APK files for storage optimization..\n"

./zipalign -P 16 -f 4 release/app-release-unsigned.apk release/app-release-unsigned-but-its-aligned.apk 2>/dev/null


# Sign APK with keystore Java file

printf "\t[4/5] Signing aligned APK..\n"

./apksigner sign --ks auto_deployer-dependencies/quick-release-key.jks --out release/app-release-signed.apk release/app-release-unsigned-but-its-aligned.apk <<< "123123" 1>/dev/null

# Removing symbolic links and intermediate apk files

rm ./zipalign ./apksigner ./release/app-release-unsigned.apk release/app-release-unsigned-but-its-aligned.apk ./release

# Removing keystore file for testing

rm auto_deployer-dependencies/quick-release-key.jks

printf "\t[5/5] Signed APK file created successfully. File location:\n\t\t /app/build/outputs/apk/release/app-release-signed.apk\n\n"

#### NEW

#ln -s app/build/outputs/apk/release/app-release-signed.apk
#ln -s auto_deployer-dependencies/gh_2.95.0_macOS_amd64/bin/gh

result=$(gh release view 2>&1)
if [ "$result" = "release not found" ];
	then gh release create v0.1 --latest --notes-file "auto_deployer-dependencies/release-notes.txt" --title "Test auto_release" app-release-signed.apk
fi

#clear init release
#gh release delete v0.1 -y --cleanup-tag

