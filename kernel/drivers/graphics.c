#include <system.h>

extern long framebuffer;
extern long width;
extern char vga_font[];

void plot_px(int x, int y, unsigned long hex) {
    unsigned long fb_i = x + width * y;

    DRF_O_32(framebuffer + fb_i * sizeof(unsigned long), hex);

    return;
}

void plot_char(char c, int x, int y, unsigned long hex_fg, unsigned long hex_bg) {
    int orig_x = x;
    int i;
    int j;

    for (i = 0; i < 16; i++) {
        for (j = 0; j < 8; j++) {
            if ((vga_font[c * 16 + i] >> 7 - j) & 1)
                plot_px(x++, y, hex_fg);
            else
                plot_px(x++, y, hex_bg);
        }
        y++;
        x = orig_x;
    }

    return;
}

void test_graphics(void) {
    int i;

    /* just draw a line */

    for (i = 0; i < 400; i++)
        plot_px(i, i, (unsigned long)0x777777);

    /* plot some chars */

    for (i = 0; i < 40; i++)
        plot_char(i + '0', i * 8, 0, (unsigned long)0, (unsigned long)0x777777);

    return;
}
