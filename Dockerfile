

#	AUTO_DEPLOYER 2026 DOCKERFILE
#	PG 0

#	TABLE OF CONTENTS + DESCRIPTION




#	PURPOSE							PAGE
#	------------------------------------------------	----

#	DOCKERFILE INITIALIZATION				1

#	PACKAGE DEPENDENCIES					2
	
#	ANDROID APP AND DEPLOYMENT SOURCE FILE RETRIEVAL	3

#	ANDROID APP BUILD TOOL RETRIEVAL			4




#	This Dockerfile builds a deployable Cloud Run container
#	with the following:

	# The source code of the TestApp Android app on GitHub
	
	# The Shell script that builds and deploys TestApp on GitHub
 
	# Any package/tool required to build or deploy TestApp




#	NOTE: This Dockerfile should be placed in the same directory 
#	as the Android app source files AND pushed already to the GitHub repo
#	intended for deployment

















#							       PG 1: CTRL + F ->


#	AUTO_DEPLOYER 2026 DOCKERFILE
#	PG 1

#	DOCKERFILE INITIALIZATION


#	Base image is Ubuntu with HomeBrew installed
#	for package installation convenience

#	Root acess user may be implied already TODO

FROM 	homebrew/brew:master
USER 	root

# 	All following commands executed in /workspace directory

WORKDIR /workspace

RUN 	apt-get -y update



































# <- PG 0: CTRL + B					       PG 2: CTRL + F ->


#	AUTO_DEPLOYER 2026 DOCKERFILE
#	PG 2

#	PACKAGE DEPENDENCIES


#	ncat, Linux tool for TCP communication 
#	Google Cloud Run requirement

RUN	apt-get install -y ncat


#	JDK (Java)
#	Required to compile app source code into releasable APK
	
RUN 	apt-get install -y openjdk-17-jdk && \
	apt-get install -y openjdk-17-jre


# 	GitHub CLI (gh) Installation and Authentication
#	Used in auto_deployer script for repo release management	

#	NOTE: GitHub repo authorization will be done later in Dockerfile

RUN	brew install gh -q





























# <- PG 1: CTRL + B					       PG 3: CTRL + F ->


#	AUTO_DEPLOYER 2026 DOCKERFILE
#	PG 3

#	ANDROID APP AND DEPLOYMENT SOURCE FILE RETRIEVAL 


#	Adding Android application source files to container
#	(via GitHub repo)

RUN	git clone https://github.com/amctheperson/TestApp -q


#	Adding executable auto-deployment bash script to container
#	(via another GitHub repo)
	
RUN	git clone https://github.com/amctheperson/auto_deployer -q && \

	rm auto_deployer/Dockerfile && \

	mv auto_deployer/* . && \
	chmod +x ./auto_deployer.sh && \

	rm -rf auto_deployer

CMD 	[ "./auto_deployer.sh" ]

#	Adding sensitive deployment dependency files to container 
#	(via Google Drive link)

#	NOTE: In practice this would be stored in a private server

RUN	apt-get install -y pipx && \
	pipx ensurepath && \

	pipx run gdown \
https://drive.google.com/file/d/1nGnuv-AVpiQxb3hz5Qh67XQ6msREv85Z/view?usp=sharing -O local-dependencies.zip && \
	unzip local-dependencies.zip

#	Authorizing GitHub CLI with GitHub Personal Access Token

RUN	gh auth login --with-token < local-dependencies/github_PA_token.txt 












# <- PG 2: CTRL + B					       PG 4: CTRL + F ->


#	AUTO_DEPLOYER 2026 DOCKERFILE
#	PG 4

#	ANDROID APP BUILD TOOL RETRIEVAL


	# Retrieving Android SDK command-line (not build) tools zip
	# (via Google Drive)
	 
	# Note: This zip file (164 MB) is too large for GitHub (< 100 MB)
	# and pulling from Google Drive via gdown is faster to implement 
	# than trying to curl the third link on Android Studio's website
 
RUN	pipx run gdown \
	https://drive.google.com/file/d/1XjTqN58f65WP4Kp-c-HNg-zydx9Er3cO/view?usp=sharing -O commandlinetools-linux.zip && \	
	unzip commandlinetools-linux.zip -d sdk

	# Reorganizing sdk directory to format expected by SDK Manager

RUN	cd sdk && \ 
	mv cmdline-tools latest && \ 
	mkdir cmdline-tools && \ 
	mv latest cmdline-tools/latest && \ 
	cd .. 

	# Retrieving build tools via SDK Manager
	
RUN	ln -s sdk/cmdline-tools/latest/bin/sdkmanager ./sdkmanager && \
	echo y | ./sdkmanager --install "build-tools;37.0.0"  && \
	rm sdkmanager && \

	mv sdk local-dependencies/sdk





















# <- PG 3: CTRL + B
