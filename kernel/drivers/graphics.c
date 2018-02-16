#include <system.h>

extern long framebuffer;
extern long width;

void plot_px(int x, int y, unsigned long hex) {
    unsigned long fb_i = x + width * y;

    DRF_O_32(framebuffer + fb_i * sizeof(unsigned long), hex);

    return;
}

void test_graphics(void) {
    int i;

    /* just draw a line */

    for (i = 0; i < 400; i++)
        plot_px(i, i, 0x008888ff);

    return;
}
