//
// Copyright 2012-2013 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "PHOpenGLView.h"

#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <GLUT/glut.h>

@implementation PHOpenGLView {
  NSOpenGLContext *m_context;
}

- (id)initWithFrame:(NSRect)frame {

  NSOpenGLPixelFormatAttribute attrs[] = {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFADepthSize, 32,
    0
  };

  NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

  self = [super initWithFrame:frame];
  if (self) {
    m_context = [[NSOpenGLContext alloc] initWithFormat:format shareContext:nil];
  }
  return self;
}

- (void)drawRect:(NSRect)rect {

  [m_context clearDrawable];
  [m_context setView:self];
  [m_context makeCurrentContext];

  glClearColor(0,0,0,0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glViewport( 0,0,[self frame].size.width,[self frame].size.height );
  glMatrixMode(GL_PROJECTION);   glLoadIdentity();
  glMatrixMode(GL_MODELVIEW);    glLoadIdentity();

  [self draw];

  [m_context flushBuffer];
  [ NSOpenGLContext clearCurrentContext];
}

- (void)draw {

  glMatrixMode(GL_PROJECTION);
  gluPerspective(25,[self frame].size.width / [self frame].size.height,1,100);
  glTranslatef(0,0,-10);

  glColor3f(1,1,1);
  glutWireTeapot(1);
}
@end
