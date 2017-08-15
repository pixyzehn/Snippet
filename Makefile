INSTALL_PATH = /usr/local/bin/Snippet

install:
	swift package --enable-prefetching update
	swift build --enable-prefetching -c release -Xswiftc -static-stdlib
	cp -f .build/release/Snippet $(INSTALL_PATH)

uninstall:
	rm -f $(INSTALL_PATH)
