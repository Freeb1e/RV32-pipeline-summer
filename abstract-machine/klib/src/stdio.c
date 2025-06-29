#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>


#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)
#define INT_MAX 0x7fffffff

int printf(const char *fmt, ...) {
  char buf[1024];
  va_list args;
  va_start(args, fmt);
  int ret = vsprintf(buf, fmt, args);
  va_end(args);
  for (int i = 0; i < ret; i++) {
    putch(buf[i]);
  }
  return ret;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  int ret = vsnprintf(out, 0x7fffffff, fmt, ap);
  return ret;
}

int sprintf(char *out, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int ret = vsprintf(out, fmt, args);
  va_end(args);
  return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int ret = vsnprintf(out, n, fmt, args);
  va_end(args);
  return ret;
}

#define INT_BUF_SIZE 32

typedef struct {
    bool left_justify;    // '-'
    bool force_sign;      // '+'
    bool space;           // ' '
    bool alternate_form;  // '#'
    bool zero_pad;        // '0'
    int width;            // 宽度值（或通过*指定）
    int precision;        // 精度值（或通过*指定）
    enum {
        LENGTH_NONE,
        LENGTH_HH,
        LENGTH_H,
        LENGTH_L,
        LENGTH_LL,
        LENGTH_LONG_DOUBLE
    } length;
    char specifier;       // 转换类型（如d, u, f等）
} FormatSpec;

static void append_char(char **buf, size_t *size, size_t *count, char c) {
    if (*size > 0) {
        *(*buf)++ = c;
        (*size)--;
    }
    (*count)++;
}

static void append_str(char **buf, size_t *size, size_t *count, const char *s, int len) {
    while (len-- > 0 && *s) {
        append_char(buf, size, count, *s++);
    }
}

static void append_padding(char **buf, size_t *size, size_t *count, char pad, int len) {
    while (len-- > 0) {
        append_char(buf, size, count, pad);
    }
}

int isdigit(char c) {
    return c >= '0' && c <= '9';
}

static const char *parse_format(const char *fmt, FormatSpec *spec, va_list *ap) {
    memset(spec, 0, sizeof(*spec));
    spec->width = -1;
    spec->precision = -1;
    fmt++;

    // 解析标志
    while (*fmt) {
        switch (*fmt) {
            case '-': spec->left_justify = true; break;
            case '+': spec->force_sign = true; break;
            case ' ': spec->space = true; break;
            case '#': spec->alternate_form = true; break;
            case '0': spec->zero_pad = true; break;
            default: goto parse_width;
        }
        fmt++;
    }

parse_width:
    // 解析宽度
    if (*fmt == '*') {
        spec->width = va_arg(*ap, int);
        fmt++;
    } else if (isdigit(*fmt)) {
        spec->width = 0;
        while (isdigit(*fmt)) {
            spec->width = spec->width * 10 + (*fmt - '0');
            fmt++;
        }
    }

    // 解析精度
    if (*fmt == '.') {
        fmt++;
        if (*fmt == '*') {
            spec->precision = va_arg(*ap, int);
            fmt++;
        } else {
            spec->precision = 0;
            while (isdigit(*fmt)) {
                spec->precision = spec->precision * 10 + (*fmt - '0');
                fmt++;
            }
        }
    }

    // 解析长度修饰符
    switch (*fmt) {
        case 'h':
            if (fmt[1] == 'h') {
                spec->length = LENGTH_HH;
                fmt += 2;
            } else {
                spec->length = LENGTH_H;
                fmt++;
            }
            break;
        case 'l':
            if (fmt[1] == 'l') {
                spec->length = LENGTH_LL;
                fmt += 2;
            } else {
                spec->length = LENGTH_L;
                fmt++;
            }
            break;
        case 'L':
            spec->length = LENGTH_LONG_DOUBLE;
            fmt++;
            break;
        default: break;
    }

    // 解析转换类型
    spec->specifier = *fmt++;
    return fmt;
}

static void format_integer(char **buf, size_t *size, size_t *count, FormatSpec *spec, uintmax_t num, bool is_negative) {
    char tmp[INT_BUF_SIZE];
    int base = 10;
    const char *digits = "0123456789abcdef";
    int tmp_pos = 0;

    switch (spec->specifier) {
        case 'o': base = 8; break;
        case 'x': break;
        case 'X': digits = "0123456789ABCDEF"; break;
        case 'u': break;
        default: base = 10; break;
    }

    // 转换为字符串（逆序）
    do {
        tmp[tmp_pos++] = digits[num % base];
        num /= base;
    } while (num > 0);

    int len = tmp_pos;
    int leading_zeros = (spec->precision > len) ? (spec->precision - len) : 0;
    if (spec->precision == 0 && len == 0) leading_zeros = 0;

    // 符号处理
    char sign = '\0';
    if (is_negative) sign = '-';
    else if (spec->force_sign) sign = '+';
    else if (spec->space) sign = ' ';

    int sign_len = (sign != '\0') ? 1 : 0;
    int total_len = sign_len + leading_zeros + len;

    // 处理宽度和填充
    int padding = (spec->width > total_len) ? (spec->width - total_len) : 0;
    char pad_char = (spec->zero_pad && !spec->left_justify) ? '0' : ' ';

    // 输出
    if (!spec->left_justify && pad_char == ' ') {
        append_padding(buf, size, count, pad_char, padding);
    }

    if (sign) {
        append_char(buf, size, count, sign);
    }

    if (!spec->left_justify && pad_char == '0') {
        append_padding(buf, size, count, pad_char, padding);
    }

    append_padding(buf, size, count, '0', leading_zeros);

    while (tmp_pos > 0) {
        append_char(buf, size, count, tmp[--tmp_pos]);
    }

    if (spec->left_justify) {
        append_padding(buf, size, count, ' ', padding);
    }
}

static void handle_integer(char **buf, size_t *size, size_t *count, FormatSpec *spec, va_list *ap) {
    uintmax_t num = 0;
    bool is_negative = false;

    switch (spec->specifier) {
        case 'd':
        case 'i': {
            intmax_t signed_num;
            switch (spec->length) {
                case LENGTH_HH: signed_num = (signed char)va_arg(*ap, int); break;
                case LENGTH_H:  signed_num = (short)va_arg(*ap, int); break;
                case LENGTH_L:  signed_num = va_arg(*ap, long); break;
                case LENGTH_LL: signed_num = va_arg(*ap, long long); break;
                default:        signed_num = va_arg(*ap, int); break;
            }
            is_negative = (signed_num < 0);
            num = is_negative ? -(uintmax_t)signed_num : (uintmax_t)signed_num;
            break;
        }
        case 'u':
        case 'o':
        case 'x':
        case 'X': {
            switch (spec->length) {
                case LENGTH_HH: num = (unsigned char)va_arg(*ap, unsigned int); break;
                case LENGTH_H:  num = (unsigned short)va_arg(*ap, unsigned int); break;
                case LENGTH_L:  num = va_arg(*ap, unsigned long); break;
                case LENGTH_LL: num = va_arg(*ap, unsigned long long); break;
                default:        num = va_arg(*ap, unsigned int); break;
            }
            break;
        }
        default: return;
    }

    format_integer(buf, size, count, spec, num, is_negative);
}

static void handle_string(char **buf, size_t *size, size_t *count, FormatSpec *spec, va_list *ap) {
    const char *s = va_arg(*ap, const char *);
    if (!s) s = "(null)";

    int max_len = (spec->precision >= 0) ? spec->precision : INT_MAX;
    int len = 0;
    while (len < max_len && s[len]) len++;

    int padding = (spec->width > len) ? (spec->width - len) : 0;

    if (!spec->left_justify) {
        append_padding(buf, size, count, ' ', padding);
    }

    append_str(buf, size, count, s, len);

    if (spec->left_justify) {
        append_padding(buf, size, count, ' ', padding);
    }
}

int vsnprintf(char *buf, size_t size, const char *fmt, va_list ap) {
    size_t count = 0;
    char *dest = buf;
    size_t remaining = size;

    while (*fmt) {
        if (*fmt != '%') {
            append_char(&dest, &remaining, &count, *fmt++);
            continue;
        }

        FormatSpec spec;
        const char *next = parse_format(fmt, &spec, &ap);
        if (!next) {
            fmt++;
            continue;
        }
        fmt = next;

        switch (spec.specifier) {
            case 'd':
            case 'i':
            case 'u':
            case 'o':
            case 'x':
            case 'X':
                handle_integer(&dest, &remaining, &count, &spec, &ap);
                break;
            case 's':
                handle_string(&dest, &remaining, &count, &spec, &ap);
                break;
            case 'c': {
                char c = (char)va_arg(ap, int);
                append_char(&dest, &remaining, &count, c);
                break;
            }
            case '%':
                append_char(&dest, &remaining, &count, '%');
                break;
            // 其他转换类型可在此扩展
            default:
                break;
        }
    }

    if (size > 0) *dest = '\0';
    return count;
}

#endif
