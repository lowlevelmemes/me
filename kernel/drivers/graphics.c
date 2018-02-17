#asm
imod:
    cwd
    idiv bx
    mov ax, dx
    ret
#endasm

#define BACKGROUND_COLOUR       0x00008888
#define WINDOW_BORDERS          0x00ffffff
#define TITLE_BAR_BACKG         0x00003377
#define TITLE_BAR_FOREG         0x00ffffff
#define WINDOW_ROWS             25
#define WINDOW_COLS             80
#define TITLE_BAR_THICKNESS     18
#define TEXT_BG                 0x00000000
#define TEXT_FG                 0x00cccccc
#define CURSOR_BG               0x00ffffff
#define CURSOR_FG               0x00000000

extern unsigned long *framebuffer;
extern long width;
extern long height;
extern char vga_font[];

unsigned long *fb = 0;
long screen_needs_refresh = 0;

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
    plot_char(c, x * 8 + wptr->x, y * 16 + wptr->y + TITLE_BAR_THICKNESS, hex_fg, hex_bg);
    wptr->grid[x + y * WINDOW_COLS] = c;
    return;
}

void draw_cursor(long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    plot_char(wptr->grid[wptr->cursor_x + wptr->cursor_y * WINDOW_COLS],
        wptr->x + wptr->cursor_x * 8, wptr->y + wptr->cursor_y * 16 + TITLE_BAR_THICKNESS, CURSOR_FG, CURSOR_BG);
    return;
}

void scroll(long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    long i;

    /* notify grid */
    for (i = WINDOW_COLS; i < WINDOW_ROWS * WINDOW_COLS; i++)
        wptr->grid[i - WINDOW_COLS] = wptr->grid[i];
    /* clear the last line of the screen */
    for (i = WINDOW_ROWS * WINDOW_COLS - WINDOW_COLS; i < WINDOW_ROWS * WINDOW_COLS; i++)
        wptr->grid[i] = ' ';

    return;
}

void tty_set_cursor_pos(long x, long y, long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    wptr->cursor_x = x;
    wptr->cursor_y = y;
    return;
}

void tty_putchar(char c, long windowid) {
    struct window_t *wptr = get_window_ptr(windowid);
    switch (c) {
        case 0x00:
            break;
        case 0x0A:
            if (wptr->cursor_y == (WINDOW_ROWS - 1)) {
                tty_set_cursor_pos(0, (WINDOW_ROWS - 1), windowid);
                scroll(windowid);
                screen_needs_refresh = 1;
            } else
                tty_set_cursor_pos(0, (wptr->cursor_y + 1), windowid);
                screen_needs_refresh = 1;
            break;
        case 0x08:
            if (wptr->cursor_x || wptr->cursor_y) {
                if (wptr->cursor_x)
                    wptr->cursor_x--;
                else {
                    wptr->cursor_y--;
                    wptr->cursor_x = WINDOW_COLS - 1;
                }
                plot_char_grid(' ', wptr->cursor_x, wptr->cursor_y,
                    TEXT_FG, TEXT_BG, windowid);
            }
            screen_needs_refresh = 1;
            break;
        default:
            plot_char_grid(c, wptr->cursor_x++, wptr->cursor_y,
                TEXT_FG, TEXT_FG, windowid);
            if (wptr->cursor_x == WINDOW_COLS) {
                wptr->cursor_x = 0;
                wptr->cursor_y++;
            }
            if (wptr->cursor_y == WINDOW_ROWS) {
                wptr->cursor_y--;
                scroll(windowid);
            }
            screen_needs_refresh = 1;
    }
    return;
}

void tty_print(char *str, long windowid) {
    long i;

    for (i = 0; str[i]; i++)
        tty_putchar(str[i], windowid);

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
    for (i = 0; i < WINDOW_COLS * WINDOW_ROWS; i++)
        wptr->grid[i] = ' ';

    return windowid;
}

void tty_refresh(void) {
    long i;
    long j;
    long x;

    /* clear screen */
    for (i = 0; i < width * height; i++)
        fb[i] = BACKGROUND_COLOUR;

    /* draw every window */
    for (j = 0; ; j++) {
        struct window_t *wptr = get_window_ptr(j);
        if (!wptr) {
            fb_swap();
            return;
        }

        /* draw the title bar */
        for (x = 0; x < TITLE_BAR_THICKNESS; x++)
            for (i = 0; i < WINDOW_COLS * 8; i++)
                plot_px(wptr->x + i, wptr->y + x, TITLE_BAR_BACKG);

        /* draw the title */
        for (i = 0; wptr->title[i]; i++)
            plot_char(wptr->title[i], wptr->x + 8 + i * 8, wptr->y + 1,
                TITLE_BAR_FOREG, TITLE_BAR_BACKG, j);

        /* interpret the grid and print the chars */
        for (i = 0; i < (WINDOW_COLS * WINDOW_ROWS); i++) {
            plot_char_grid(wptr->grid[i], i % WINDOW_COLS, i / WINDOW_COLS,
                TEXT_FG, TEXT_BG, j);
        }

        draw_cursor(j);

        /* draw the window border */

        for (i = 0; i < WINDOW_COLS * 8; i++)
            plot_px(wptr->x + i, wptr->y, WINDOW_BORDERS);
        for (i = 0; i < TITLE_BAR_THICKNESS; i++)
            plot_px(wptr->x, wptr->y + i, WINDOW_BORDERS);
        for (i = 0; i < TITLE_BAR_THICKNESS; i++)
            plot_px(wptr->x + (WINDOW_COLS * 8 - 1), wptr->y + i, WINDOW_BORDERS);

        for (i = 0; i < WINDOW_COLS * 8; i++)
            plot_px(wptr->x + i, wptr->y + TITLE_BAR_THICKNESS, WINDOW_BORDERS);
        for (i = 0; i < WINDOW_COLS * 8; i++)
            plot_px(wptr->x + i, wptr->y + (WINDOW_ROWS * 16 - 1) + TITLE_BAR_THICKNESS, WINDOW_BORDERS);
        for (i = 0; i < WINDOW_ROWS * 16; i++)
            plot_px(wptr->x, wptr->y + i + TITLE_BAR_THICKNESS, WINDOW_BORDERS);
        for (i = 0; i < WINDOW_ROWS * 16; i++)
            plot_px(wptr->x + (WINDOW_COLS * 8 - 1), wptr->y + i + TITLE_BAR_THICKNESS, WINDOW_BORDERS);
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
    tty_print("the quick brown fox jumps over the lazy dog\n", 3);
    tty_print("the quick brown fox jumps over the lazy dog\n", 3);
    tty_print("the quick brown fox jumps over the lazy dog\n", 3);
    tty_print("the quick brown fox jumps over the lazy dog\n", 3);
    tty_print("the quick brown fox jumps over the lazy dog\n", 3);
    tty_print("the quick brown fox jumps over the lazy dog\n", 3);
    tty_print("the quick brown fox jumps over the lazy dog\n", 3);
    tty_print("the quick brown fox jumps over the lazy dog\n", 3);
    tty_print("the quick brown fox jumps over the lazy dog", 3);
    tty_print("the quick brown fox jumps over the lazy dog\n", 2);
    tty_print("the quick brown fox jumps over the lazy dog\n", 2);
    tty_print("the quick brown fox jumps over the lazy dog\n", 2);
    tty_print("the quick brown fox jumps over the lazy dog\n", 2);
    tty_print("the quick brown fox jumps over the lazy dog\n", 2);
    tty_print("the quick brown fox jumps over the lazy dog\n", 2);
    tty_print("the quick brown fox jumps over the lazy dog\n", 2);
    tty_print("the quick brown fox jumps over the lazy dog\n", 2);
    tty_print("the quick brown fox jumps over the lazy dog", 2);

    return;
}
