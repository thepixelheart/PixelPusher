import PixelDriver.*;

PixelDriver pixelDriver;

int socket;
PGraphics buf;
PImage img;

void setup()  {
  // Create a connection to the Heart's Driver.
  socket = pixelDriver.openSocket("127.0.0.1", "Demo Processing");
  print(socket);
  if (socket < 0) {
    exit();
  }

  // We use an off-screen buffer to render our frame once and then ship
  // the baby bits off to the Heart and the Processing canvas.
  buf = createGraphics(48, 32, P3D);
  buf.rectMode(CENTER);

  // Bigger canvas for seeing our pixels, yay!
  size(480, 320);
  frameRate(30);
}

void renderBuffer() {
  // Always render to the buf object :)
  buf.background(255, 204, 0);
  buf.rect(10,10,2,10);
}

void draw() {
  buf.beginDraw();
  renderBuffer();
  buf.endDraw();

  // Create an image of the buffer.
  img = buf.get(0, 0, buf.width, buf.height);

  img.loadPixels();
  // Shoot dem pixels straight to the Heart's Driver.
  pixelDriver.flyPixelsFly(socket, img);
  
  // Draws to the Processing canvas.
  img.resize(480, 320);
  image(img, 0, 0);
}

void exit() {
  // Close the connection to the Heart's Driver.
  pixelDriver.closeSocket(socket);
}

