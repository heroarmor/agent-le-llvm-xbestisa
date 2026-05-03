/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

struct hdr { unsigned ver:4; unsigned ihl:4; unsigned tos; unsigned len:16; };
int parse(unsigned char *buf) {
    struct hdr h;
    h.ver = buf[0] >> 4;
    h.ihl = buf[0] & 0xF;
    h.tos = buf[1];
    h.len = ((unsigned)buf[2] << 8) | buf[3];
    return (int)h.len + h.ihl * 4;
}
