#include <string.h>
#include <stddef.h>
#include <stdio.h>
#include <stdint.h>
#include <assert.h>

typedef uint32_t word;

static const word K1 = 0x5A827999;
static const word K2 = 0X6ED9EBA1;
static const word K3 = 0x8F1BBCDC;
static const word K4 = 0xCA62C1D6;

static word w_and(word w1, word w2) {
    return w1 & w2;
}

static word w_or(word w1, word w2) {
    return w1 | w2;
}

static word w_xor(word w1, word w2) {
    return w1 ^ w2;
}

static word w_not(word w) {
    return ~w;
}

static word circular(unsigned u, word w) {
        return (w << u) | (w >> (32 - u));
}

static word little_to_big_endian(word w) {
    word result;
    unsigned char* w_p = (unsigned char*) &w;
    unsigned char* r_p = (unsigned char*) &result;
    for (size_t i = 0; i < 4; i++) {
        r_p[i] = w_p[3 - i];
    }
    return result;
}

static void padding(const char* message, const word* padded) {
    uint64_t length = strlen(message);
    unsigned char* p_length = (unsigned char*) &length;
    unsigned char* w_p = (unsigned char*) padded;
    for (size_t i = 0; i < 56; i++) {
        if (i < length) {
            w_p[i] = message[i];
            continue;
        }
        if (i == length) {
            w_p[i] = '\x80';
            continue;
        }
        w_p[i] = '\x00';
    }
    length *= 8;
    for (size_t i = 0; i < 8; i++) {
        w_p[56 + i] = p_length[7 - i];
    }
}

int main(int argc, char** argv) {
    assert(little_to_big_endian(0x61626364) == 0x64636261);
    assert(w_not(0x61626364) == 0x9E9D9C9B);
    assert(w_xor(0x61626364, 0x62636465) == 0x03010701);
    assert(w_or(0x61626364, 0x62636465) == 0x63636765);
    assert(w_and(0x61626364, 0x62636465) == 0x60626064);
    assert(circular(3, 0x61626364) == 0xB131B23);
    word padded[16] = {'\0'};
    unsigned char* w_p = (unsigned char*) &padded;
    padding(argv[1], padded);
    for (size_t i = 0; i < 64; i++) {
        if (i % 4 == 0) {
            printf(" ");
        }
        if (i % 16 == 0) {
            printf("\n");
        }
        printf("%0.2x", w_p[i]);
    }
}
