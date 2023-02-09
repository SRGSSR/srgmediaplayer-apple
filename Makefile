#!/usr/bin/xcrun make -f

.PHONY: all
all: test-ios test-tvos

.PHONY: test-ios
test-ios:
	@echo "Running iOS unit tests..."
	@xcodebuild test -scheme SRGMediaPlayer -destination 'platform=iOS Simulator,name=iPhone 11' 2> /dev/null
	@echo "... done.\n"

.PHONY: test-tvos
test-tvos:
	@echo "Running tvOS unit tests..."
	@xcodebuild test -scheme SRGMediaPlayer -destination 'platform=tvOS Simulator,name=Apple TV' 2> /dev/null
	@echo "... done.\n"

.PHONY: rbenv
rbenv:
	@echo "Installing needed ruby version if missing..."
	@Scripts/rbenv-install.sh "./"
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo "   all                 Build and run unit tests for all platforms"
	@echo "   test-ios            Build and run unit tests for iOS"
	@echo "   test-tvos           Build and run unit tests for tvOS"
	@echo "   rbenv               Install needed ruby version if missing"
	@echo "   help                Display this help message"