INSTALL_PATH = /usr/local/bin/Snippet

install:
	swift package update
	swift build -c release -Xswiftc -static-stdlib
	cp -f .build/release/Snippet $(INSTALL_PATH)

uninstall:
	rm -f $(INSTALL_PATH)
