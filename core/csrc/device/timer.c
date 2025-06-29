#include <time.h>
#include <device.h>
#include <stdint.h>

static uint64_t boot_time = 0;

uint64_t get_time_internal(){
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_COARSE, &ts);
    uint64_t us;
    us = ts.tv_sec * 1000000 + ts.tv_nsec / 1000;
    return us;
}

uint64_t get_time(){
    if(boot_time==0) {
        boot_time = get_time_internal();
    }
    return get_time_internal() - boot_time;
}