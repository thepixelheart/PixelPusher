import PixelDriver.*;

PixelDriver pixelDriver;

void setup()  {
  int status = pixelDriver.openSocket("127.0.0.1");
  print(status);
  if(status != 3) {
    exit();
  }
}

void draw() {
}

void exit() {
}

