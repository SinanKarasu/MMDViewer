PROJECT := MMDViewer.xcodeproj
SCHEME := MMDViewer
DERIVED_DATA := $(CURDIR)/.build/DerivedData
INSTALL_DIR ?= $(HOME)/Applications

.PHONY: build install run

build:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" \
		-configuration Release -destination 'platform=macOS' \
		-derivedDataPath "$(DERIVED_DATA)" build

install:
	INSTALL_DIR="$(INSTALL_DIR)" ./Scripts/install-app.sh

run:
	open "$(INSTALL_DIR)/MMDViewer.app"
