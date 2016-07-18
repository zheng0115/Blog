#include <stdio.h>
int main() {
  // void (^blk)() = ^{printf("Block\n");};
  // blk();
  // return 0;

  typedef void (^blk_t)();
  blk_t blk = ^{};
  return 0;
}
