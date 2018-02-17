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

long tty_cols = 0;
long tty_rows = 0;
char *tty_grid = 0;
long cursor_x = 0;
long cursor_y = 0;

void *sbrk(long);

void plot_px(long x, long y, unsigned long hex) {
    long fb_i = x + width * y;

    framebuffer[fb_i] = hex;

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

void plot_char_grid(char c, long x, long y, unsigned long hex_fg, unsigned long hex_bg) {
    plot_char(c, x * 8, y * 16, hex_fg, hex_bg);
    tty_grid[x + y * tty_cols] = c;
    return;
}

void clear_cursor(void) {
    plot_char(tty_grid[cursor_x + cursor_y * tty_cols],
        cursor_x * 8, cursor_y * 16, (unsigned long)0, (unsigned long)0x888888);
    return;
}

void draw_cursor(void) {
    plot_char(tty_grid[cursor_x + cursor_y * tty_cols],
        cursor_x * 8, cursor_y * 16, (unsigned long)0x888888, (unsigned long)0);
    return;
}

void tty_refresh(void) {
    long i;

    clear_cursor();
    /* interpret the grid and print the chars */
    for (i = 0; i < (tty_rows * tty_cols); i++) {
        plot_char_grid(tty_grid[i], i % tty_cols, i / tty_cols,
            (unsigned long)0, (unsigned long)0x888888);
    }
    draw_cursor();
    return;
}

void scroll(void) {
    long i;

    /* notify grid */
    for (i = tty_cols; i < tty_rows * tty_cols; i++)
        tty_grid[i - tty_cols] = tty_grid[i];
    /* clear the last line of the screen */
    for (i = tty_rows * tty_cols - tty_cols; i < tty_rows * tty_cols; i++)
        tty_grid[i] = ' ';

    tty_refresh();
    return;
}

void tty_set_cursor_pos(long x, long y) {
    clear_cursor();
    cursor_x = x;
    cursor_y = y;
    draw_cursor();
    return;
}

void tty_putchar(char c) {
    switch (c) {
        case 0x00:
            break;
        case 0x0A:
            if (cursor_y == (tty_rows - 1)) {
                tty_set_cursor_pos(0, (tty_rows - 1));
                scroll();
            } else
                tty_set_cursor_pos(0, (cursor_y + 1));
            break;
        case 0x08:
            if (cursor_x || cursor_y) {
                clear_cursor();
                if (cursor_x)
                    cursor_x--;
                else {
                    cursor_y--;
                    cursor_x = tty_cols - 1;
                }
                plot_char_grid(' ', cursor_x, cursor_y,
                    (unsigned long)0, (unsigned long)0x888888);
                draw_cursor();
            }
            break;
        default:
            plot_char_grid(c, cursor_x++, cursor_y,
                (unsigned long)0, (unsigned long)0x888888);
            if (cursor_x == tty_cols) {
                cursor_x = 0;
                cursor_y++;
            }
            if (cursor_y == tty_rows) {
                cursor_y--;
                scroll();
            }
            draw_cursor();
    }
    return;
}

void tty_print(char *str) {
    long i;

    for (i = 0; str[i]; i++)
        tty_putchar(str[i]);

    return;
}

void init_graphics(void) {
    long i;

    tty_cols = width / 8;
    tty_rows = height / 16;

    tty_grid = sbrk(tty_rows * tty_cols);

    /* zero out the thing here */
    for (i = 0; i < tty_rows * tty_cols; i++)
        tty_grid[i] = ' ';

    tty_refresh();

    /* print hello world */
    tty_print("Welcome to the biggest meme of them all.");

    return;
}
