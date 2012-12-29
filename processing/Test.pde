import PixelDriver.*;

PixelDriver pixelDriver;
int socket;
PGraphics buf;
PImage img;

void setup()  {
  socket = pixelDriver.openSocket("127.0.0.1");
  print(socket);
  if (socket < 0) {
    exit();
  }

  buf = createGraphics(48, 32, P3D);
  buf.rectMode(CENTER);

  size(48, 32);
}

void draw() {
  // Render to the buffer.
  buf.beginDraw();
  buf.rect(10,10,2,10);
  buf.endDraw();

  img = buf.get(0, 0, buf.width, buf.height);
  image(img, 0, 0);
}

void exit() {
  pixelDriver.closeSocket(socket);
}

