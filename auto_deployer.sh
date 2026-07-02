printf "\nAUTO DEPLOYER 2026\n\n"

#	=== Compiling APK for release ==

# Build unsigned APK with Gradle
# TODO Determine what inside Android Studio fixes the initial build

printf "\t[1/7] Assembling unsigned APK..\n"

./gradlew assemble >/dev/null


# Generate keystore Java file (if non-existent)

if ! [ -f auto_deployer-dependencies/quick-release-key.jks ]
then	
	printf "\t[2/7] Generating keystore file...\n"

	keytool -genkey -keystore \
	auto_deployer-dependencies/quick-release-key.jks \
	-keyalg RSA -keysize 2048 -validity 10000 \
	-alias andrewc < auto_deployer-dependencies/signature_details.txt \
	2>/dev/null
else
	printf "\t[2/7] Existing keystore file located...\n" 
fi


# Symbolic links for zipalign and apksigner, releases folder too
# For ease of implementation, removed at end of script to avoid clutter

ln -s auto_deployer-dependencies/selected-Android-SDK-build-tools-37.0.0/zipalign ./zipalign
ln -s auto_deployer-dependencies/selected-Android-SDK-build-tools-37.0.0/apksigner ./apksigner
ln -s app/build/outputs/apk/release/ ./


# Align APK files (required before signing APK file)

printf "\t[3/7] Aligning uncompressed APK files for storage optimization..\n"

./zipalign -P 16 -f 4 release/app-release-unsigned.apk \
release/app-release-unsigned-but-its-aligned.apk 2>/dev/null


# Sign APK with keystore Java file

printf "\t[4/7] Signing aligned APK..\n"

./apksigner sign --ks auto_deployer-dependencies/quick-release-key.jks \
--out release/app-release-signed.apk \
release/app-release-unsigned-but-its-aligned.apk <<< "123123" 1>/dev/null

# Removing symbolic links and intermediate apk files

rm ./zipalign ./apksigner ./release/app-release-unsigned.apk release/app-release-unsigned-but-its-aligned.apk ./release


printf "\t[5/7] Signed APK file created successfully. File location:\n\t\t /app/build/outputs/apk/release/app-release-signed.apk\n"



#	=== Uploading release to GitHub repo ===

# Establishing symbolic links for convenience (and readability)

ln -s app/build/outputs/apk/release/app-release-signed.apk
ln -s auto_deployer-dependencies/gh_2.95.0_macOS_amd64/bin/gh


# Get current commit hash of master branch of repo
# aka most recently committed hash

most_recent_commit_hash=$(git rev-parse origin/master)


# Getting info on most recently committed hash
# --no-patch flag removes diff info
# --format option used to return only the email subject (message) of the commit

new_release_title=$(git show --format="%s" --no-patch "$most_recent_commit_hash")   
new_release_notes_file="auto_deployer-dependencies/release-notes.txt"


# release tag defaults to initial release version
tag=v0.1

printf "\t[6/7] "

# Check if any repo releases exist

result=$(gh release view 2>&1)
if [ "$result" = "release not found" ]; then

	printf "Uploading initial release to repo..\n"

else
	printf "Uploading new release to repo..\n"

	# gh release used to get info on latest release on repo
	# --json option used to get JSON string with tagName field
	# --jq option used also to filter said JSON string to just
	# the single entry

	curVersion=$(gh release view --json tagName --jq '.tagName')
	newVersion=""

	# For this proof-of-concept we can assume
	# that this auto-deploy pipeline is for minor updates
	# rather than major updates

	# Therefore release version numbers will never "round up majorly"
	# like 0.9 -> 1.0

	# Thus for new version numbers we can take the old version number
	# and append a "1" if last num is 9
	# otherwise increase last digit by 1
	# like 0.9 -> 0.91 or 2.3 -> 2.4

	if [ ${curVersion:(-1)} = "9" ]; then
 
		newVersion="${curVersion}1" 
	else    
		# curVersion substring that is full string - the final char

		prefix=${curVersion:0:$((${#curVersion}-1))} 
	 
		# Increments final char of curVersion as int
 
		suffix=$((${curVersion:(-1)}+1)) 
	 
		newVersion="${prefix}${suffix}"

		tag=$newVersion
	fi
fi

new_link=$(gh release create $tag --latest --notes-file "$new_release_notes_file" --title "$new_release_title" app-release-signed.apk)

printf "\t[7/7] Release uploaded to GitHub repo. Page link:\n\t\t$new_link\n"

# Removing established symbolic links 
rm app-release-signed.apk gh

# Testing commands

# Removing keystore file

#rm auto_deployer-dependencies/quick-release-key.jks

# Removing releases

#clear init release
#gh release delete v0.1 -y --cleanup-tag
