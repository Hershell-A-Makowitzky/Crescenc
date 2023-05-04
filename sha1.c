#include <stddef.h>
#include <stdio.h>
#include <string.h>

#define K1 0x5A827999
#define K2 0x6ED9EBA1
#define K3 0x8F1BBCDC
#define K4 0xCA62C1D6

void format(unsigned char buffer[64]) {
    for (size_t i = 0; i < 64; i++) {
        if (i != 0 && i % 4 == 0) {
            printf(" ");
        }
        if (i != 0 && i % 16 == 0) {
            printf("\n");
        }
        printf("%0.2x", buffer[i]);
    }
}

void formatU(unsigned u) {
    unsigned long long formater = 0xFFULL << 0x18;
    unsigned comparator = 0x18;
    for (size_t i = 0; i < 4; i++) {
        printf("%0.2x", (unsigned) (formater & u) >> comparator);
        formater >>= 0x08;
        comparator -= 0x08;
    }
}

void padding(unsigned char message[64]) {
    size_t len_byte = (size_t) strnlen((const char*) message, 64);
    /* printf("%d\n", len_byte); */
    size_t len_bit = len_byte * 8;
    unsigned long long formater = 0xffULL << 0x38;
    unsigned comparator = 0x38;
    if (len_byte < 57) {
        for (size_t i = 0; i < 64; i++) {
            if (i < len_byte) {
                continue;
            }
            if (i == len_byte && len_byte < 56) {
                message[i] = 0x80;
                continue;
            }
            if (i < 56) {
                message[i] = 0x00;
                continue;
            }
            message[i] = (formater & len_bit) >> comparator;
            formater >>= 0x08;
            comparator -= 0x08;
        }
    }
    /* if (56 <= len_byte && len_byte < 60) { */
    /*     formater >>= 0x38; */
    /*     compara */
    /*     for (size_t i = 0; i < 4; i++) { */
    /*         message[60 + i] = (len_bit & formater) >> formater; */
    /*         formater >>= 0x08; */
    /*     } */
    /* } */
}

unsigned f0(unsigned b, unsigned c, unsigned d) { return (b & c) | ((~b) & d);}

unsigned f20(unsigned b, unsigned c, unsigned d) { return b ^ c ^ d; }

unsigned f40(unsigned b, unsigned c, unsigned d) { return (b & c) | (b & d) | (c & d); }

unsigned f60(unsigned b, unsigned c, unsigned d) { return b ^ c ^ d; }

void digest(unsigned char message[64]) {
    unsigned buff_a[5];
    unsigned buff_b[5] = { 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0 };
    unsigned seq[80];
    unsigned temp;

    for (size_t i = 0, j = 0; i < 16; i ++, j += 4) {

        seq[i] = *((unsigned*) &message[j]);

        /* unsigned char* ptr = (unsigned char*) &seq[i]; */
        /* for (int k = 0; k < 4; k++) { */
        /*     printf("%0.2x", *(ptr + (sizeof(unsigned char) * k))); */
        /* } */
    }
}

int main(void) {
    /* unsigned char buffer[64] = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"; */
    unsigned char buffer[64] = "hello";
    padding(buffer);
    format(buffer);
    puts("");
    formatU(f0(buffer[0], buffer[1], buffer[2]));
    puts("");
    formatU(f20(buffer[0], buffer[1], buffer[2]));
    puts("");
    formatU(f40(buffer[0], buffer[1], buffer[2]));
    puts("");
    formatU(f60(buffer[0], buffer[1], buffer[2]));
    puts("");
    digest(buffer);
}
