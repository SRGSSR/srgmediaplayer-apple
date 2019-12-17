#!/usr/bin/xcrun make -f

CARTHAGE_FOLDER=Carthage
CARTHAGE_FLAGS=--platform iOS,tvOS --cache-builds --new-resolver

.PHONY: all
all: bootstrap
	@echo "Building the project..."
	@xcodebuild build
	@echo "... done.\n"

.PHONY: bootstrap
bootstrap:
	@echo "Bootstrapping dependencies..."
	@carthage bootstrap $(CARTHAGE_FLAGS)
	@echo "... done.\n"

.PHONY: update
update:
	@echo "Updating dependencies..."
	@carthage update $(CARTHAGE_FLAGS)
	@echo "... done.\n"

.PHONY: package
package: bootstrap
	@echo "Packaging binaries..."
	@mkdir -p archive
	@carthage build --no-skip-current
	@carthage archive --output archive
	@echo "... done.\n"

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
	@rm -rf $(CARTHAGE_FOLDER)
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo "   all                         Build project dependencies and the project"
	@echo "   bootstrap                   Build dependencies as declared in Cartfile.resolved"
	@echo "   update                      Update and build dependencies"
	@echo "   package                     Build and package the framework for attaching to github releases"
	@echo "   clean                       Clean the project and its dependencies"
	@echo "   help                        Display this message"
