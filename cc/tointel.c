#include <stdio.h>
#include <ctype.h>

int main(void) {

    for (;;) {
        char val[64];
        int c = getchar();
        if (c == '-' || isdigit(c)) {
            /* store number */
            for (size_t i = 0; ; i++) {
                val[i] = c;
                c = getchar();
                if (!isdigit(c)) {
                    val[++i] = 0;
                    break;
                }
            }
            if (c == '[') {
                printf("[%s+", val);
                c = getchar();
            } else {
                fputs(val, stdout);
            }
        }
        if (c == EOF)
            goto out;
        putchar(c);
    }

out:
    return 0;

}
