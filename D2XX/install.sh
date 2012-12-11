#!/bin/bash

cp bin/10.5-10.7/libftd2xx.1.2.2.dylib /usr/local/lib/libftd2xx.1.2.2.dylib
ln -sf /usr/local/lib/libftd2xx.1.2.2.dylib /usr/local/lib/libftd2xx.dylib
cp bin/ftd2xx.h /usr/local/include/ftd2xx.h
cp bin/WinTypes.h /usr/local/include/WinTypes.h
