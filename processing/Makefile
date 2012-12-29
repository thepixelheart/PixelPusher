CC = gcc

CFLAGS     = -m32 -fast -fomit-frame-pointer
LDFLAGS    = -m32 -framework JavaVM -dynamiclib
CLASSPATH  = /Applications/Processing.app/Contents/Resources/Java/core.jar
HEADERPATH = /System/Library/Frameworks/JavaVM.framework/Headers
DESTPATH   = ~/Documents/Processing/Libraries/PixelDriver
JNILIB     = libPixelDriver.jnilib

all: PixelDriver.jar $(JNILIB)

PixelDriver.jar: PixelDriver.java
	javac -d . -classpath $(CLASSPATH) PixelDriver.java
	jar -fc PixelDriver.jar PixelDriver

PixelDriver_PixelDriver.h: PixelDriver.jar
	javah PixelDriver.PixelDriver

$(JNILIB): PixelDriver.c PixelDriver_PixelDriver.h
	$(CC) $(CFLAGS) -I$(HEADERPATH) PixelDriver.c -c
	$(CC) $(LDFLAGS) PixelDriver.o -o $(JNILIB)

install:
	mkdir -p $(DESTPATH)/library
	mkdir -p $(DESTPATH)/examples/Test
	cp PixelDriver.jar $(DESTPATH)/library
	cp $(JNILIB) $(DESTPATH)/library
	cp export.txt $(DESTPATH)/library
	cp Test.pde $(DESTPATH)/examples/Test

clean:
	rm -rf *.o PixelDriver PixelDriver.jar PixelDriver_PixelDriver.h $(JNILIB)
