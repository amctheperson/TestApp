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


# git rev-parse mainly used for manipulating hashes into something readable
# git rev-parse used here to get current hash of master branch on the repo
# aka most recently committed hash

most_recent_commit_hash=$(git rev-parse origin/master)

# git show is a function for getting commit info by hash ID

# format includes only the "subject" of the commit
# as commits are default formatted as an email

# no-patch flag removes all the diff (all the file changes in a commit, line by line)

new_release_title=$(git show --format="%s" --no-patch "$most_recent_commit_hash")   
new_release_notes_file="auto_deployer-dependencies/release-notes.txt"

tag=v0.1

printf "\t[6/5] "

result=$(gh release view 2>&1)
if [ "$result" = "release not found" ]; then

	printf "Uploading initial release to repo..\n"

else
	printf "Uploading new release to repo..\n"

	# gh release view gets info on a GitHub release
	# here it is being defaulted to the latest release
	# and outputing a JSON string of just the tag name field
	# and filtering said JSON string to just the tag name entry

	curVersion=$(gh release view --json tagName --jq '.tagName')
	newVersion=""

	# For the scope of this proof of concept, we can make the assumption
	# that this auto-deploy pipeline is for minor updates
	# rather than major updates
	# therefore release version numbers will never
	# "round up majorly" like 0.9 -> 1.0

	# aka 

	# just append a "1" if last num is 9
	# otherwise increase last digit by 1

	if [ ${curVersion:(-1)} = "9" ]; then
 
		newVersion="${curVersion}1" 
	else    
		# Essentially this is curVersion substring of length len(curVersion) - 1
		# starting at position 0 
		# and ${#curVersion} is the length of curVersion 
		# and the double parentheses are for evaluating an arithmetic expression
		# which we use to decrement the length value by 1 
		prefix=${curVersion:0:$((${#curVersion}-1))} 
	 
		# Increments final character of curVersion as an integer 
		suffix=$((${curVersion:(-1)}+1)) 
	 
		newVersion="${prefix}${suffix}"

		tag=$newVersion
	fi
fi

new_link=$(gh release create $tag --latest --notes-file "$new_release_notes_file" --title "$new_release_title" app-release-signed.apk)

printf "\t[7/5] Release uploaded to GitHub repo. Page link:\n\t\t$new_link\n"


#clear init release
#gh release delete v0.1 -y --cleanup-tag
