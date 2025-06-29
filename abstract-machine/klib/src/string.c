#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t i = 0;
  while(s[i] != '\0') {
    i++;
  }
  return i;
}

char *strcpy(char *dst, const char *src) {
  size_t i = 0;
  while(src[i] != '\0') {
    dst[i] = src[i];
    i++;
  }
  dst[i] = '\0';
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t i;
  for(i = 0; i < n && src[i] != '\0'; i++) {
    dst[i] = src[i];
  }
  for(; i < n; i++) {
    dst[i] = '\0';
  }
  return dst;
}

char *strcat(char *dst, const char *src) {
  size_t i, j;
  for(i = 0; dst[i] != '\0'; i++);
  for(j = 0; src[j] != '\0'; j++) {
    dst[i + j] = src[j];
  }
  dst[i + j] = '\0';
  return dst;
}

int strcmp(const char *s1, const char *s2) {
  size_t i;
  for(i = 0; s1[i] != '\0' && s2[i] != '\0'; i++) {
    if(s1[i] != s2[i]) {
      return s1[i] - s2[i];
    }
  }
  return s1[i] - s2[i];
}

int strncmp(const char *s1, const char *s2, size_t n) {
  size_t i;
  for(i = 0; i < n && s1[i] != '\0' && s2[i] != '\0' ; i++) {
    if(s1[i] != s2[i]) {
      return s1[i] - s2[i];
    }
  }
  if (i==n)
    return 0;
  return s1[i] - s2[i];
}

void *memset(void *s, int c, size_t n) {
  size_t i;
  for(i = 0; i < n; i++) {
    ((uint8_t *)s)[i] = (uint8_t) c;
  }
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  size_t i;
  if(dst < src) {
    for(i = 0; i < n; i++) {
      ((uint8_t *)dst)[i] = ((uint8_t *)src)[i];
    }
  } else {
    for(i = n - 1; i >= 0; i--) {
      ((uint8_t *)dst)[i] = ((uint8_t *)src)[i];
    }
  }
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  size_t i;
  for(i = 0; i < n; i++) {
    ((uint8_t *)out)[i] = ((uint8_t *)in)[i];
  }
  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  size_t i;
  for(i = 0; i < n; i++) {
    if(((uint8_t *)s1)[i] != ((uint8_t *)s2)[i]) {
      return ((uint8_t *)s1)[i] - ((uint8_t *)s2)[i];
    }
  }
  return 0;
}

#endif
