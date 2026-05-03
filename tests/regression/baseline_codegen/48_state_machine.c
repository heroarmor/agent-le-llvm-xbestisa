/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int sm(const char *s) {
    int state = 0;
    for (; *s; ++s) {
        switch (state) {
          case 0: state = (*s == 'a') ? 1 : 0; break;
          case 1: state = (*s == 'b') ? 2 : 0; break;
          case 2: state = (*s == 'c') ? 3 : 0; break;
          case 3: return 1;
        }
    }
    return 0;
}
