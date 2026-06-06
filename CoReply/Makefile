# Makefile for CoReply XcodeGen and Building

.PHONY: generate open clean test help

help:
	@echo "Available commands:"
	@echo "  make generate  - Run XcodeGen to generate CoReply.xcodeproj"
	@echo "  make open      - Open project in Xcode"
	@echo "  make clean     - Clean build directories and DerivedData"
	@echo "  make test      - Run tests inside Simulator"

generate:
	xcodegen generate

open:
	open CoReply.xcodeproj

clean:
	rm -rf build/
	rm -rf CoReply.xcodeproj
	rm -rf CoReply.xcworkspace
	@echo "Cleaned generated files and folders."

test:
	xcodebuild test \
	  -scheme CoReplyApp \
	  -project CoReply.xcodeproj \
	  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
