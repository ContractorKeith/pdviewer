# Developer shortcuts. Requires Xcode and xcodegen (brew install xcodegen).
SCHEME   = pdviewer
DERIVED  = build
APP      = $(DERIVED)/Build/Products/Debug/pdviewer.app
XCB      = xcodebuild -project pdviewer.xcodeproj -scheme $(SCHEME) -derivedDataPath $(DERIVED) -destination 'platform=macOS' -quiet

.PHONY: gen build test run lint clean

gen:
	xcodegen generate

build: gen
	$(XCB) -configuration Debug build

test: gen
	$(XCB) -configuration Debug test

run: build
	open $(APP) $(PDF)

lint:
	swiftlint lint --quiet

clean:
	rm -rf $(DERIVED) pdviewer.xcodeproj
