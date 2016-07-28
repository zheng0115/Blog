#include <stdio.h>

int main() {
  __block int a = 0;
  void (^blk)() = ^{
    a = 1;
    printf("Block\n");
  };
  blk();
  return 0;
}
