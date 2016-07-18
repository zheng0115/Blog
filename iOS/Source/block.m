#include <stdio.h>
int main() {
  void (^blk)() = ^{printf("Block\n");};
  blk();
  return 0;
}
