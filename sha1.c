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
    puts("");
}

unsigned formatU(unsigned u) {
    unsigned long long formater = 0xFFULL << 0x18;
    unsigned comparator = 0x18;
    unsigned reverter = 0x00;
    unsigned char uch;
    unsigned result;
    unsigned char* p_result = (unsigned char*) &result + (sizeof(unsigned char) * 3);
    for (size_t i = 0; i < 4; i++) {
        uch = (formater & u) >> comparator;
        *p_result = uch;
        formater >>= 0x08;
        comparator -= 0x08;
        p_result -= sizeof(unsigned char);
    }
    return result;
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

unsigned circular(unsigned u, unsigned word) {
    if (u > 0 && u < 32) {
        /* unsigned local = *word; */
        return (word << u) | (word >> (32 - u));
    }
    if (u == 0) {
        return word;
    }
    printf("Error: circular function 'n' exceeded interval '0 <= n < 32'");
    return 0;
}


unsigned f0(unsigned b, unsigned c, unsigned d) { return (b & c) | ((~b) & d);}

unsigned f20(unsigned b, unsigned c, unsigned d) { return b ^ c ^ d; }

unsigned f40(unsigned b, unsigned c, unsigned d) { return (b & c) | (b & d) | (c & d); }

unsigned f60(unsigned b, unsigned c, unsigned d) { return b ^ c ^ d; }

unsigned (f)(unsigned t, unsigned a, unsigned b, unsigned c) {
    if (t < 20) {
        return f0(a, b, c);
    }
    if (t < 40) {
        return f20(a, b, c);
    }
    if (t < 60) {
        return f40(a, b, c);
    }
    if ( t < 80) {
        return f60(a, b, c);
    }
    return 0;
}

unsigned k(unsigned u) {
    if (u < 20) {
        return K1;
    }
    if (u < 40) {
        return K2;
    }
    if (u < 60) {
        return K3;
    }
    if (u < 80) {
        return K4;
    }
    return 0;
}


void digest(unsigned char message[64]) {
    unsigned buff_a[5];
    unsigned buff_b[5] = { 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0 };
    unsigned seq[80];
    unsigned temp;

    for (size_t i = 0, j = 0; i < 80; i ++, j += 4) {

        if (i < 14) {
            seq[i] = formatU(*((unsigned*) &message[j]));
        } else if (i >= 14 && i < 16) {
            seq[i] = *((unsigned*) &message[j]);
        } else {
            seq[i] = circular(1, (seq[i - 3] ^ seq[i - 8] ^ seq[i - 14] ^ seq[i - 16]));
        }
        printf("%0.2x", seq[i]);
        /* unsigned char* ptr = (unsigned char*) &seq[i]; */
        /* for (int k = 0; k < 4; k++) { */
        /*     printf("%0.2x", *(ptr + (sizeof(unsigned char) * k))); */
        /* } */
    }
    puts("");

    for (size_t i = 0; i < 5; i++) {
        buff_a[i] = buff_b[i];
    }

    for (size_t i = 0; i < 80; i++) {
        temp = circular(5, buff_a[0]) + f(i, buff_a[1], buff_a[2], buff_a[3]) + buff_a[4] + seq[i] + k(i);
        buff_a[4] = buff_a[3];
        buff_a[3] = buff_a[2];
        buff_a[2] = circular(30, buff_a[1]);
        buff_a[1] = buff_a[0];
        buff_a[0] = temp;
    }

    buff_b[0] = buff_b[0] + buff_a[0];
    buff_b[1] = buff_b[1] + buff_a[1];
    buff_b[2] = buff_b[2] + buff_a[2];
    buff_b[3] = buff_b[3] + buff_a[3];
    buff_b[4] = buff_b[4] + buff_a[4];

    for (size_t i = 0; i < 5; i++) {
        printf("%0.8x", buff_b[i]);
    }

    puts("");

}

int main(void) {
    /* unsigned char buffer[64] = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"; */
    unsigned char buffer[64] = "abcde";
    padding(buffer);
    /* format(buffer); */
    /* puts(""); */
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
    digest(buffer);
}
