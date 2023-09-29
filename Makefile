build:
	cc -g -O0 -framework AppKit -framework CoreVideo -framework QuartzCore  osx_dbg/*.m -o osx_dbg.o
package:
	rm -f osx_dbg.app/Contents/MacOS/osx_dbg
	rm -rf osx_dbg.app/Contents/MacOS/osx_dbg.o.dSYM
	cp -f osx_dbg.o osx_dbg.app/Contents/MacOS/osx_dbg
	cp -rf osx_dbg.o.dSYM osx_dbg.app/Contents/MacOS/osx_dbg.dSYM
run:
	open osx_dbg.app
