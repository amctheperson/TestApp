echo "AUTO DEPLOYER 2026\n"


# Build unsigned APK with Gradle

echo "\t[1/5] Assembling unsigned APK.."

./gradlew assemble >/dev/null


# Generate keystore Java file (if non-existent)

if ! [ -f auto_deployer-dependencies/quick-release-key.jks ]
then	
	echo "\t[2/5] Generating keystore file..."
	keytool -genkey -keystore auto_deployer-dependencies/quick-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias andrewc < auto_deployer-dependencies/signature_details.txt 2>/dev/null
else
	echo "\t[2/5] Existing keystore file located..." 
fi


# Symbolic links for zipalign and apksigner, releases folder too
# For ease of implementation, removed at end of script to avoid clutter

ln -s auto_deployer-dependencies/selected-Android-SDK-build-tools-37.0.0/zipalign ./zipalign
ln -s auto_deployer-dependencies/selected-Android-SDK-build-tools-37.0.0/apksigner ./apksigner
ln -s app/build/outputs/apk/release/ ./


# Align APK files (required before signing APK file)

echo "\t[3/5] Aligning uncompressed APK files for storage optimization.."

./zipalign -P 16 -f 4 release/app-release-unsigned.apk release/app-release-unsigned-but-its-aligned.apk 2>/dev/null


# Sign APK with keystore Java file

echo "\t[4/5] Signing aligned APK.."

./apksigner sign --ks auto_deployer-dependencies/quick-release-key.jks --out release/app-release-signed.apk release/app-release-unsigned-but-its-aligned.apk <<< "123123" 1>/dev/null

# Removing symbolic links and intermediate apk files

rm ./zipalign ./apksigner ./release/app-release-unsigned.apk release/app-release-unsigned-but-its-aligned.apk ./release

# Removing keystore file for testing

rm auto_deployer-dependencies/quick-release-key.jks

echo "\t[5/5] Signed APK file created successfully. File location:\n\t\t /app/build/outputs/apk/release/app-release-signed.apk"
