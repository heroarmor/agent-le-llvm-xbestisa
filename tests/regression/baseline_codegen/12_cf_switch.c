/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int sw(int x) {
    switch (x) {
      case 0: return 100;
      case 1: return 200;
      case 2: return 300;
      case 3: return 400;
      case 4: return 500;
      default: return -1;
}
}
