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

#include <jni.h>
#include "PixelDriver_PixelDriver.h"

#include <stdio.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

JNIEXPORT jint JNICALL Java_PixelDriver_PixelDriver_OpenSocket(
    JNIEnv *env,
    jclass  this,
    jstring serverAddress)  {
  char* serverAddressCString = 0;

  {
    const char *_serverAddressCString = (* env)->GetStringUTFChars(env, serverAddress, 0);
    serverAddressCString = strdup(_serverAddressCString);
    (* env)->ReleaseStringUTFChars(env, serverAddress, _serverAddressCString);
  }
  
  if (0 == serverAddressCString || strlen(serverAddressCString) == 0) {
    return -1;
  }

  // Create the socket.
  int sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0) {
    return -2;
  }
  
  struct hostent *server = gethostbyname(serverAddressCString);
  if (server == NULL) {
    return -3;
  }
  
  free(serverAddressCString);
  serverAddressCString = 0;
  
  struct sockaddr_in serv_addr;
  
  // Zero out the socket structure.
  bzero((char *)&serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  bcopy((char *)server->h_addr,
        (char *)&serv_addr.sin_addr.s_addr,
        server->h_length);
  serv_addr.sin_port = htons(54000);
  if (connect(sockfd, (const struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
    return -4;
  }
	return sockfd;
}

JNIEXPORT jint JNICALL Java_PixelDriver_PixelDriver_CloseSocket(
    JNIEnv *env,
    jclass  this,
    jint    socket)  {
  close(socket);
}

JNIEXPORT jint JNICALL Java_PixelDriver_PixelDriver_FlyPixelsFly(
    JNIEnv *env,
    jclass  this,
    jint    socket,
    jobject image)  {
  if (socket <= 0) {
    return -1;
  }

  jclass imageClass = (* env)->GetObjectClass(env, image);
  jfieldID pixelsId = (* env)->GetFieldID(env, imageClass, "pixels", "[I");
  jobject pixelsData = (* env)->GetObjectField(env, image, pixelsId);
  jintArray* pixelsArray = (jintArray *)&pixelsData;
  jint* pixels = (* env)->GetIntArrayElements(env, *pixelsArray, NULL);
  jsize nElements = (* env)->GetArrayLength(env, *pixelsArray);

  int n = write(socket, &nElements, sizeof(jsize));
  if (n < 0) {
    return -5;
  }

  n = write(socket, pixels, sizeof(jint) * nElements);
  if (n < 0) {
    return -5;
  }

  (* env)->ReleaseIntArrayElements(env, *pixelsArray, pixels, 0);
}
