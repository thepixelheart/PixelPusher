import PixelDriver.*;

PixelDriver pixelDriver;

void setup()  {
  int status = pixelDriver.openSocket();
  print(status);
  if(status != 3) {
    exit();
  }
}

void draw() {
}

void exit() {
}

