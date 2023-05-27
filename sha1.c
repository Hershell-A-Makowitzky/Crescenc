#include <stdio.h>
#include <string.h>
#include <stddef.h>

typedef unsigned char word[4];

static const word K1 = "\x5A\x82\x79\x99";
static const word K2 = "\x6E\xD9\xEB\xA1";
static const word K3 = "\x8F\x1B\xBC\xDC";
static const word K4 = "\xCA\x62\xC1\xD6";


static void w_and(const word w1, const word w2, word result) {
    for (size_t i = 0; i < 4; i++) {
        result[i] = w1[i] & w2[i];
    }
}

static void w_or(const word w1, const word w2, word result) {
    for (size_t i = 0; i < 4; i++) {
        result[i] = w1[i] | w2[i];
    }
}

static void w_xor(const word w1, const word w2, word result) {
    for (size_t i = 0; i < 4; i++) {
        result[i] = w1[i] ^ w2[i];
    }
}

static void w_not(const word w, word result) {
    for (size_t i = 0; i < 4; i++) {
        result[i] = ~w[i];
    }
}

static void circular(unsigned u, word* w) {
    if (u > 0 && u < 32) {
        unsigned* ch_p = (unsigned*) w;
        *ch_p = (*ch_p << u) | (*ch_p >> (32 - u));
    }
}

/* void format(unsigned char buffer[64]) { */
/*     for (size_t i = 0; i < 64; i++) { */
/*         if (i != 0 && i % 4 == 0) { */
/*             printf(" "); */
/*         } */
/*         if (i != 0 && i % 16 == 0) { */
/*             printf("\n"); */
/*         } */
/*         printf("%0.2x", buffer[i]); */
/*     } */
/*     puts(""); */
/* } */

/* unsigned formatU(unsigned u) { */
/*     unsigned long long formater = 0xFFULL << 0x18; */
/*     unsigned comparator = 0x18; */
/*     unsigned reverter = 0x00; */
/*     unsigned char uch; */
/*     unsigned result; */
/*     unsigned char* p_result = (unsigned char*) &result + (sizeof(unsigned char) * 3); */
/*     for (size_t i = 0; i < 4; i++) { */
/*         uch = (formater & u) >> comparator; */
/*         *p_result = uch; */
/*         formater >>= 0x08; */
/*         comparator -= 0x08; */
/*         p_result -= sizeof(unsigned char); */
/*     } */
/*     return result; */
/* } */

void padding(word message[16]) {
    /* size_t len_byte = (size_t) strnlen((const char*) message, 64); */
    /* printf("%d\n", len_byte); */
    /* size_t len_bit = len_byte * 8; */
    unsigned long long formater = 0xffULL << 0x38;
    unsigned comparator = 0x38;
    unsigned len = 0;
    unsigned char done = 0;
    for (size_t i = 0; i < 16; i++) {
        for (size_t j = 0; j < 4; j++) {
            if (message[i][j] == 0x00 && !done) {
                message[i][j] = 0x80;
                done = 1;
                continue;
            }
            if (!done) {
                len += 8;
            }
            printf("Lenght %d\n", len);
            if (i >= 14) {
                message[i][j] = (formater & len) >> comparator;
                formater >>= 0x08;
                comparator -= 0x08;
            }
        }
    }
    /* if (len_byte < 57) { */
    /*     for (size_t i = 0; i < 64; i++) { */
    /*         if (i < len_byte) { */
    /*             continue; */
    /*         } */
    /*         if (i == len_byte && len_byte < 56) { */
    /*             message[i] = 0x80; */
    /*             continue; */
    /*         } */
    /*         if (i < 56) { */
    /*             message[i] = 0x00; */
    /*             continue; */
    /*         } */
    /*         message[i] = (formater & len_bit) >> comparator; */
    /*         formater >>= 0x08; */
    /*         comparator -= 0x08; */
    /*     } */
    /* } */
    /* if (56 <= len_byte && len_byte < 60) { */
    /*     formater >>= 0x38; */
    /*     compara */
    /*     for (size_t i = 0; i < 4; i++) { */
    /*         message[60 + i] = (len_bit & formater) >> formater; */
    /*         formater >>= 0x08; */
    /*     } */
    /* } */
}



static void f0(const word b, const word c, const word d, word result) {
    w_not(b, result);
    w_and(result, d, result);
}

/* static void f20(unsigned b, unsigned c, unsigned d) { return b ^ c ^ d; } */

/* static void f40(unsigned b, unsigned c, unsigned d) { return (b & c) | (b & d) | (c & d); } */

/* static void f60(unsigned b, unsigned c, unsigned d) { return b ^ c ^ d; } */

/* unsigned (f)(unsigned t, unsigned a, unsigned b, unsigned c) { */
/*     if (t < 20) { */
/*         return f0(a, b, c); */
/*     } */
/*     if (t < 40) { */
/*         return f20(a, b, c); */
/*     } */
/*     if (t < 60) { */
/*         return f40(a, b, c); */
/*     } */
/*     if ( t < 80) { */
/*         return f60(a, b, c); */
/*     } */
/*     return 0; */
/* } */

void k(unsigned u, word value) {
    if (u < 20) {
        for (size_t i = 0; i < 4; i++) {
            value[i] = K1[i];
        }
    }
    if (u < 40) {
        for (size_t i = 0; i < 4; i++) {
            value[i] = K2[i];
        }
    }
    if (u < 60) {
        for (size_t i = 0; i < 4; i++) {
            value[i] = K3[i];
        }
    }
    if (u < 80) {
        for (size_t i = 0; i < 4; i++) {
            value[i] = K4[i];
        }
    }
}

/* void digest(word message[16]) { */
/*     word buff_a[5] = { "\x67\x45\x23\x01", "\xEF\xCD\xAB\x89", "\x98\xBA\xDC\xFE", "\x10\x32\x54\x76", "\xC3\xD2\xE1\xF0" }; */
/*     word buff_b[5] = { "\x67\x45\x23\x01", "\xEF\xCD\xAB\x89", "\x98\xBA\xDC\xFE", "\x10\x32\x54\x76", "\xC3\xD2\xE1\xF0" }; */
/*     word seq[80]; */
/*     word temp; */

/*     for (size_t i = 0; i < 80; i++) { */

/*         if (i < 16) { */
/*         /\*     seq[i] = formatU(*((unsigned*) &message[j])); *\/ */
/*             unsigned char* p_message = (unsigned char*) &message[i]; */
/*             unsigned char* p_seq = (unsigned char*) &seq[i]; */
/*             /\* for (size_t j = 0; j < 4; j++) { *\/ */
/*             /\*    *p_seq = *p_message; *\/ */
/*             /\*    printf("%0.2x", *p_seq); *\/ */
/*             /\*    p_seq++; *\/ */
/*             /\*    p_message++; *\/ */
/*             /\* } *\/ */
/*             /\* *seq[i] = *message[i]; *\/ */
/*             continue; */
/*         } */
/*         /\* if (i >= 14 && i < 16) { *\/ */
/*         /\*     seq[i] = *((unsigned*) &message[j]); *\/ */
/*         /\*     continue; *\/ */
/*         /\* } *\/ */
/*         /\* unsigned char* p_seq = (unsigned char*) &seq[i]; *\/ */
/*         if (i >= 16) { */
/*             unsigned* tmp = (unsigned*) &seq[i]; */
/*             unsigned tmp1; */
/*             tmp1 = *(tmp - 3) ^ *(tmp - 8) ^ *(tmp - 14) ^ *(tmp - 16); */
/*             circular(1, (word*) &tmp1); */
/*             /\* unsigned char* p_seq = (unsigned char*) &seq[i]; *\/ */
/*             /\* for (size_t j = 0; j < 4; j++) { *\/ */
/*             /\*    printf("%0.2x", *p_seq); *\/ */
/*             /\*    p_seq++; *\/ */
/*             /\* } *\/ */
/*         /\* word result; *\/ */
/*         /\* for (size_t j = 0; j < 4; j++) { *\/ */
/*         /\*     *p_seq = (*(p_seq - (3 * 4)) ^(*(p_seq - (8 * 4))) ^ (*(p_seq - (14 * 4))) ^ (*(p_seq - (16 * 4)))); *\/ */
/*         /\*     result[i] = *(p_seq + i); *\/ */
/*         /\*     p_seq++; *\/ */
/*         /\* } *\/ */
/*         /\* result = () *\/ */
/*         /\* seq[i] = circular(1, (seq[i - 3] ^ seq[i - 8] ^ seq[i - 14] ^ seq[i - 16])); *\/ */
/*         /\* circular(1, result); *\/ */
/*         /\* p_seq = (unsigned char*) &seq[i]; *\/ */
/*         /\* for (size_t i = 0; i < 4; i++) { *\/ */
/*         /\*     *(p_seq + i) = result[i]; *\/ */
/*         /\*     printf("%0.2x", *(p_seq + i)); *\/ */
/*         /\* } *\/ */
/*         /\* printf("%0.2x", seq[i]); *\/ */
/*         /\* unsigned char* ptr = (unsigned char*) &seq[i]; *\/ */
/*         /\* for (int k = 0; k < 4; k++) { *\/ */
/*         /\*     printf("%0.2x", *(ptr + (sizeof(unsigned char) * k))); *\/ */
/*         /\* } *\/ */
/*         } */
/*     } */
/*     puts(""); */

/*     for (size_t k = 0; k < 5; k++) { */
/*         for (size_t l = 0; l < 4; l++) { */
/*             buff_a[k][l] = buff_b[k][l]; */
/*         } */
/*     } */

/*     for (size_t i = 0; i < 80; i++) { */
/*         circular(5, (word*) buff_a[0]); */
/*         *(unsigned*) temp = *(unsigned*) buff_a[0] + f(i, *(unsigned*) buff_a[1], *(unsigned*) buff_a[2], *(unsigned*) buff_a[3]) + *(unsigned*) buff_a[4] + *(unsigned*) seq[i] + k(i); */
/*         *(unsigned*) buff_a[4] = *(unsigned*) buff_a[3]; */
/*         *(unsigned*) buff_a[3] = *(unsigned*) buff_a[2]; */
/*         word* wp = &buff_a[1]; */
/*         circular(30,  wp); */
/*         *(unsigned*) buff_a[2] = *(unsigned*) buff_a[1]; */
/*         *(unsigned*)buff_a[1] = *(unsigned*) buff_a[0]; */
/*         unsigned char* p_seq = (unsigned char*) &buff_a[0]; */
/*         for (size_t i = 0; i < 4; i++) { */
/*             *p_seq = temp[i]; */
/*         } */
/*     } */

/*     *(unsigned*) buff_b[0] = *(unsigned*) buff_b[0] + *(unsigned*) buff_a[0]; */
/*     *(unsigned*) buff_b[1] = *(unsigned*) buff_b[1] + *(unsigned*) buff_a[1]; */
/*     *(unsigned*) buff_b[2] = *(unsigned*) buff_b[2] + *(unsigned*) buff_a[2]; */
/*     *(unsigned*) buff_b[3] = *(unsigned*) buff_b[3] + *(unsigned*) buff_a[3]; */
/*     *(unsigned*) buff_b[4] = *(unsigned*) buff_b[4] + *(unsigned*) buff_a[4]; */

/*     for (size_t i = 0; i < 5; i++) { */
/*         for (size_t j = 0; j < 4; j++) { */
/*             printf("%0.2x", buff_b[i][j]); */
/*         } */
/*     } */

/*     puts(""); */
/* } */

/* void digest1(unsigned char message[64]) { */
/*     unsigned buff_a[5]; */
/*     unsigned buff_b[5] = { 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0 }; */
/*     unsigned seq[16]; */
/*     unsigned temp; */
/*     unsigned s; */
/*     for (size_t i = 0, j = 0; i < 16; i++, j += 4) { */
/*         seq[i] = *((unsigned*) &message[j]); */
/*         printf("%0.8x", seq[i]); */
/*     } */
/*     puts(""); */
/*     for (size_t i = 0; i < 5; i++) { */
/*         buff_a[i] = buff_b[i]; */
/*     } */
/*     for (size_t i = 0; i < 80; i++) { */
/*         s = i & MASK; */
/*         /\* printf("%x", s); *\/ */
/*         if (i >= 16) { */
/*             unsigned u = seq[(s + 13) & MASK] ^ seq[(s + 8) & MASK] ^ seq[(s + 2) & MASK] ^ seq[s]; */
/*             seq[s] = circular(1, u); */
/*         } */
/*         temp = circular(5, buff_a[0]) + f(i, buff_a[1], buff_a[2], buff_a[3]) + buff_a[4] + seq[s] + k(i); */
/*         buff_a[4] = buff_a[3]; */
/*         buff_a[3] = buff_a[2]; */
/*         buff_a[2] = circular(30, buff_a[1]); */
/*         buff_a[1] = buff_a[0]; */
/*         buff_a[0] = temp; */
/*     } */
/*     buff_b[0] = buff_b[0] + buff_a[0]; */
/*     buff_b[1] = buff_b[1] + buff_a[1]; */
/*     buff_b[2] = buff_b[2] + buff_a[2]; */
/*     buff_b[3] = buff_b[3] + buff_a[3]; */
/*     buff_b[4] = buff_b[4] + buff_a[4]; */

    /* puts(""); */
/*     for (size_t i = 0; i < 5; i++) { */
/*         printf("%0.8x", buff_b[i]); */
/*     } */

/*     puts(""); */
/* } */

int main(void) {
    unsigned char buffer[64] = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    /* word w = "\xEF\xCD\xAB\x89"; */
    /* word buffer[16] = { "\x61\x62\x63\x64" }; */
    /* circular(3, &buffer[0]); */
    /* unsigned char* chp = buffer[0]; */
    /* for (size_t i = 0; i < 4; i++) { */
    /*     printf("%0.2X", chp[i]); */
    /* } */
    /* puts(""); */
    padding(buffer);
    /* format(buffer); */
    word result;
    word test = {'\x61', '\x62', '\x63', '\x64'};
    word test1 = {'\x65', '\x66', '\x67', '\x68'};
    word test2 = {'\x69', '\x70', '\x71', '\x72'};
    /* w_not(test, result), w_not(result, result); */
    f0(test, test1, test2, result);
    for (size_t i = 0; i < 4; i++) {
        printf("%0.2x", result[i]);
    }
    puts("");
    /* formatU(f0(buffer[0], buffer[1], buffer[2])); */
    /* puts(""); */
    /* formatU(f20(buffer[0], buffer[1], buffer[2])); */
    /* puts(""); */
    /* formatU(f40(buffer[0], buffer[1], buffer[2])); */
    /* puts(""); */
    /* formatU(f60(buffer[0], buffer[1], buffer[2])); */
    /* puts(""); */
    /* digest(buffer); */
    /* puts(""); */
    /* unsigned tst = 12; */
    /* int result = circular(31, &tst); */
    /* printf("Main: %u : %u\n", result, tst); */
    /* unsigned result = f(52, 13, 19, 10); */
    /* printf("%u\n", result); */
    /* digest(buffer); */
    /* for (size_t i = 0; i < 4; i++) { */
    /*     printf("%0.2x", w[i]); */
    /* } */
    /* for (size_t i = 0; i < 64; i++) { */
    /*     unsigned char* p_uch = (unsigned char*) buffer; */
    /*     if (i % 4 == 0) printf(" "); */
    /*     if (i % 16 == 0) printf("\n"); */
    /*     printf("%0.2x", *(p_uch + i)); */
    /* } */
    /* printf("\n%c\n", *(unsigned char *)(buffer + 4)); */
    /* printf("%p\n", buffer); */
    /* printf("%p\n", buffer + 1); */
}
