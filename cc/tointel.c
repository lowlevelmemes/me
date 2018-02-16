#include <stdio.h>
#include <ctype.h>

int main(void) {

    for (;;) {
        char str[128];
        int c = getchar();
        if (c == '-' || c == '_' || isalnum(c)) {
            /* store string */
            for (size_t i = 0; ; i++) {
                str[i] = c;
                c = getchar();
                if (c != '_' && !isalnum(c)) {
                    str[++i] = 0;
                    break;
                }
            }
            if (c == '[') {
                printf("[%s+", str);
                c = getchar();
            } else {
                fputs(str, stdout);
            }
        }
        if (c == EOF)
            goto out;
        putchar(c);
    }

out:
    return 0;

}
