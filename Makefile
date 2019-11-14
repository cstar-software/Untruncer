clean:
	rm -r ./bundle.debug.ppcx64
	rm -r ./Untruncer.app
all:
	mkdir -p ./bundle.debug.ppcx64
	/usr/local/lib/fpc/3.3.1/ppcx64 "./sources/Main.pas" -vbr -k"-rpath @loader_path/../Frameworks" -godwarfcpp -gw -WM10.10 -FU"./bundle.debug.ppcx64" -XR"/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk" -o"./Untruncer" -Fu"." -Fu"./sources"
	mkdir -p ./Untruncer.app
	mkdir -p ./Untruncer.app/Contents
	mkdir -p ./Untruncer.app/Contents/MacOS
	mkdir -p ./Untruncer.app/Contents/Frameworks
	mkdir -p ./Untruncer.app/Contents/Resources
	mv -f ./Untruncer ./Untruncer.app/Contents/MacOS/Untruncer
	cp -f ./Info.plist.out ./Untruncer.app/Contents/Info.plist
	mkdir -p ./Untruncer.app/Contents/Resources
	mkdir -p ./Untruncer.app/Contents/Resources
	/usr/bin/ibtool --errors --warnings --notices --output-format human-readable-text --compile "./Untruncer.app/Contents/Resources/MainMenu.nib" "./BaseUI/BaseUI/Base.lproj/MainMenu.xib" --flatten YES
	mkdir -p ./Untruncer.app/Contents/Resources
	/usr/bin/ibtool --errors --warnings --notices --output-format human-readable-text --compile "./Untruncer.app/Contents/Resources/TMovieDetailsViewController.nib" "./BaseUI/BaseUI/Base.lproj/TMovieDetailsViewController.xib" --flatten YES
	mkdir -p ./Untruncer.app/Contents/Resources
	cp ./resources/app.icns ./Untruncer.app/Contents/Resources/app.icns
	mkdir -p ./Untruncer.app/Contents/Resources
	cp ./resources/untrunc ./Untruncer.app/Contents/Resources/untrunc
install:
	cp ./Untruncer.app ~/Applications/Untruncer.app
