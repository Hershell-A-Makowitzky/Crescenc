#include <stdio.h>
#include <stdlib.h>

#define ASCII "%9[]0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./:;<=>?@\\^_`{|}~]"

void clearInput() {
    while (1) {
        int canary = fgetc(stdin);
        if (canary == EOF || canary == '\n' || canary == '\0') {
            break;
        }
    }
}

void clearBuf(char* buf) {
    for (int i = 0; i < 9; i++) {
        buf[i] = '\0';
    }
}

int input() {
    char buf[10] =  {'\0'};
    loop:
    while (1) {
        printf("Put your a positive number (0-999_999_999): ");
        if (fscanf(stdin, ASCII, buf) > 0) {
            int result = 0;
            for (int i  = 0; i < 9; i++) {
                if ((buf[i] < 48 || buf[i] > 57) && buf[i] != '\0') {
                    clearInput();
                    clearBuf(buf);
                    goto loop;
                }
            }
            if (result = atoi(buf), result != 0) {
                printf("%i\n", result);
                break;
            } else {
                clearInput();
                clearBuf(buf);
                goto loop;
            }
        } else {
            clearInput();
            clearBuf(buf);
            goto loop;
        }
    }
    return 0;
}

int main(int argc, char *argv[]) {
    /* FILE* fd = fopen(argv[1], "r"); */
    input();
    /* fclose(fd); */
    return 0;
}
