#asm
imod:
    cwd
    idiv bx
    mov ax, dx
    ret
#endasm

extern unsigned long *framebuffer;
extern long width;
extern long height;
extern char vga_font[];

unsigned long *fb = 0;

struct window_t {
    char title[128];
    long x;
    long y;
    long cursor_x;
    long cursor_y;
    char grid[80 * 25];
    struct window_t *next;
};

struct window_t *windows = 0;

struct window_t *get_window_ptr(long windowid) {
    long i;
    /* check if no windows were allocated */
    if (!windows) {
        /* error */
        return (struct window_t *)0;
    } else {
        /* else crawl the linked list to the last entry */
        struct window_t *wptr = windows;
        for (i = 0; i < windowid; i++) {
            if (wptr->next) {
                wptr = wptr->next;
                continue;
            } else {
                /* error */
                return (struct window_t *)0;
            }
        }
        return wptr;
    }
}

void *sbrk(long);
void tty_refresh(void);

void fb_swap(void) {
    long i;
    for (i = 0; i < height * width; i++)
        framebuffer[i] = fb[i];
    return;
}

void plot_px(long x, long y, unsigned long hex) {
    long fb_i = x + width * y;

    fb[fb_i] = hex;

    return;
}

void plot_char(char c, long x, long y, unsigned long hex_fg, unsigned long hex_bg) {
    long orig_x = x;
    long i;
    long j;

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

void plot_char_grid(char c, long x, long y, unsigned long hex_fg, unsigned long hex_bg, long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    plot_char(c, x * 8 + wptr->x + 2, y * 16 + wptr->y + 20, hex_fg, hex_bg);
    wptr->grid[x + y * 80] = c;
    return;
}

void clear_cursor(long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    plot_char(wptr->grid[wptr->cursor_x + wptr->cursor_y * 80],
        wptr->x + wptr->cursor_x * 8 + 2, wptr->y + wptr->cursor_y * 16 + 20, (unsigned long)0xffffff, (unsigned long)0);
    return;
}

void draw_cursor(long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    plot_char(wptr->grid[wptr->cursor_x + wptr->cursor_y * 80],
        wptr->x + wptr->cursor_x * 8 + 2, wptr->y + wptr->cursor_y * 16 + 20, (unsigned long)0, (unsigned long)0xffffff);
    return;
}

void scroll(long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    long i;

    /* notify grid */
    for (i = 80; i < 25 * 80; i++)
        wptr->grid[i - 80] = wptr->grid[i];
    /* clear the last line of the screen */
    for (i = 25 * 80 - 80; i < 25 * 80; i++)
        wptr->grid[i] = ' ';

    return;
}

void tty_set_cursor_pos(long x, long y, long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    //clear_cursor(windowid);
    wptr->cursor_x = x;
    wptr->cursor_y = y;
    //draw_cursor(windowid);
    return;
}

void tty_putchar(char c, long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    switch (c) {
        case 0x00:
            break;
        case 0x0A:
            if (wptr->cursor_y == (25 - 1)) {
                tty_set_cursor_pos(0, (25 - 1), windowid);
                scroll(windowid);
                //tty_refresh();
            } else
                tty_set_cursor_pos(0, (wptr->cursor_y + 1), windowid);
                //tty_refresh();
            break;
        case 0x08:
            if (wptr->cursor_x || wptr->cursor_y) {
                clear_cursor(windowid);
                if (wptr->cursor_x)
                    wptr->cursor_x--;
                else {
                    wptr->cursor_y--;
                    wptr->cursor_x = 80 - 1;
                }
                plot_char_grid(' ', wptr->cursor_x, wptr->cursor_y,
                    (unsigned long)0xffffff, (unsigned long)0, windowid);
                //draw_cursor(windowid);
            }
            //tty_refresh();
            break;
        default:
            plot_char_grid(c, wptr->cursor_x++, wptr->cursor_y,
                (unsigned long)0xffffff, (unsigned long)0, windowid);
            if (wptr->cursor_x == 80) {
                wptr->cursor_x = 0;
                wptr->cursor_y++;
            }
            if (wptr->cursor_y == 80) {
                wptr->cursor_y--;
                scroll(windowid);
            }
            //tty_refresh();
            //draw_cursor(windowid);
    }
    return;
}

void tty_print(char *str, long windowid) {
    long i;

    for (i = 0; str[i]; i++)
        tty_putchar(str[i], windowid);

    tty_refresh();

    return;
}

void kstrcpy(char *dest, char *src) {
    long i;

    for (i = 0; src[i]; i++)
        dest[i] = src[i];

    dest[i] = 0;

    return;
}

long create_window(char *title, long x, long y) {
    long i;
    long windowid;
    struct window_t *wptr;

    /* check if no windows were allocated */
    if (!windows) {
        /* allocate root window */
        windows = sbrk(sizeof(struct window_t));
        wptr = windows;
        windowid = 0;
    } else {
        /* else crawl the linked list to the last entry */
        wptr = windows;
        for (windowid = 1; ; windowid++) {
            if (wptr->next) {
                wptr = wptr->next;
                continue;
            } else {
                wptr->next = sbrk(sizeof(struct window_t));
                wptr = wptr->next;
                break;
            }
        }
    }

    kstrcpy(wptr->title, title);
    wptr->x = x;
    wptr->y = y;
    wptr->cursor_x = 0;
    wptr->cursor_y = 0;

    /* clear the window's grid */
    for (i = 0; i < 80 * 25; i++)
        wptr->grid[i] = ' ';

    return windowid;
}

void tty_refresh(void) {
    long i;
    long j;

    /* clear screen */
    for (i = 0; i < width * height; i++)
        fb[i] = 0;

    /* draw every window */
    for (j = 0; ; j++) {
        struct window_t *wptr = get_window_ptr(j);
        if (!wptr) {
            fb_swap();
            return;
        }

        /* draw the title bar */
        for (i = 0; i < 80 * 8 + 4; i++)
            plot_px(wptr->x + i, wptr->y, (unsigned long)0xffffff);
        for (i = 0; i < 18; i++)
            plot_px(wptr->x, wptr->y + i, (unsigned long)0xffffff);
        for (i = 0; i < 18; i++)
            plot_px(wptr->x + (80 * 8 + 4), wptr->y + i, (unsigned long)0xffffff);

        /* draw the title */
        for (i = 0; wptr->title[i]; i++)
            plot_char(wptr->title[i], wptr->x + 8 + i * 8, wptr->y + 1,
                (unsigned long)0xffffff, (unsigned long)0, j);

        /* draw the window border */
        for (i = 0; i < 80 * 8 + 4; i++)
            plot_px(wptr->x + i, wptr->y + 18, (unsigned long)0xffffff);
        for (i = 0; i < 80 * 8 + 4; i++)
            plot_px(wptr->x + i, wptr->y + (25 * 16 + 4) + 18, (unsigned long)0xffffff);
        for (i = 0; i < 25 * 16 + 4; i++)
            plot_px(wptr->x, wptr->y + i + 18, (unsigned long)0xffffff);
        for (i = 0; i < 25 * 16 + 4; i++)
            plot_px(wptr->x + (80 * 8 + 4), wptr->y + i + 18, (unsigned long)0xffffff);

        /* interpret the grid and print the chars */
        for (i = 0; i < (80 * 25); i++) {
            plot_char_grid(wptr->grid[i], i % 80, i / 80,
                (unsigned long)0xffffff, (unsigned long)0, j);
        }
        draw_cursor(j);
    }

    return;
}

void init_graphics(void) {
    long i;

    fb = sbrk(width * height * sizeof(unsigned long));

    create_window("window 0", 5, 5);
    create_window("window 1", 45, 45);
    create_window("window 2", 85, 85);
    create_window("window 3", 125, 125);
    tty_refresh();

    tty_print("Next level meme!", 0);
    tty_print("yes\nno\nyes\nno\nyes", 1);
    tty_print("no", 2);
    tty_print("the quick brown fox jumps over the lazy dog", 3);

    /*tty_cols = width / 8;
    tty_rows = height / 16;*/

    /*tty_grid = sbrk(tty_rows * tty_cols);*/

    /* zero out the thing here */
    /*for (i = 0; i < tty_rows * tty_cols; i++)
        tty_grid[i] = ' ';

    tty_refresh();

    /* print hello world */
    /*tty_print("Welcome to the biggest meme of them all.");*/

    return;
}
