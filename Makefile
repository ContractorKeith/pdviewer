# Developer shortcuts. Requires Xcode and xcodegen (brew install xcodegen).
SCHEME   = pdviewer
DERIVED  = build
APP      = $(DERIVED)/Build/Products/Debug/pdviewer.app
XCB      = xcodebuild -project pdviewer.xcodeproj -scheme $(SCHEME) -derivedDataPath $(DERIVED) -destination 'platform=macOS' -quiet

.PHONY: gen build test uitest run lint clean

gen:
	xcodegen generate

build: gen
	$(XCB) -configuration Debug build

test: gen
	$(XCB) -configuration Debug test

# UI smoke test: launches the app, checks it renders, saves screenshots to $(SHOTS).
SHOTS ?= $(DERIVED)/shots
uitest: gen
	mkdir -p $(SHOTS)
	xcodebuild -project pdviewer.xcodeproj -scheme pdviewerUITests -derivedDataPath $(DERIVED) \
	  -destination 'platform=macOS' -quiet TEST_RUNNER_PDVIEWER_SHOTS=$(abspath $(SHOTS)) test

run: build
	open $(APP) $(PDF)

lint:
	swiftlint lint --quiet

clean:
	rm -rf $(DERIVED) pdviewer.xcodeproj
