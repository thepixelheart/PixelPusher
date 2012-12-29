/*
  Copyright 2012 Jeff Verkoeyen
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  
     http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 */

package PixelDriver;

public class PixelDriver {
	static {    	
		System.loadLibrary("PixelDriver");
	}

	private static native int OpenSocket(String serverName);
	private static native int CloseSocket(int socket);
	private static native int FlyPixelsFly(int socket, Object image);

	public static int openSocket(String serverName) {
		return OpenSocket(serverName); 
	}

	public static int closeSocket(int socket) {
		return CloseSocket(socket); 
	}

	public static int flyPixelsFly(int socket, Object image) {
		return FlyPixelsFly(socket, image); 
	}
}
