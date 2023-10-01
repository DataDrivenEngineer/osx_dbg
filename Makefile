build: clean
	# Compile all ObjC++ files
	cc -c -g -O0 -std=c++17 -Iinclude/metal-cpp osx_dbg/osx_dbg.mm -o mm.o
	# Compile all C++ files
	cc -c -g -O0 -std=c++17 -Iinclude/metal-cpp osx_dbg/osx_dbg.cpp -o cpp.o
	# Link
	cc -g -O0 -lc++ -framework AppKit -framework CoreVideo -framework QuartzCore -framework Metal mm.o cpp.o -o osx_dbg.o
	# Generate debug symbols
	dsymutil osx_dbg.o
	echo ""
package:
	cp -f osx_dbg.o osx_dbg.app/Contents/MacOS/osx_dbg
	cp -rf osx_dbg.o.dSYM osx_dbg.app/Contents/MacOS/osx_dbg.dSYM
	echo ""
run:
	open osx_dbg.app
clean:
	# Remove executable and debug symbols from the app's bundle
	rm -f osx_dbg.app/Contents/MacOS/osx_dbg
	rm -rf osx_dbg.app/Contents/MacOS/osx_dbg.o.dSYM
	# Remove executable and debug symbols from build location
	rm -f *.o
	rm -rf *.o.dSYM
	echo ""
