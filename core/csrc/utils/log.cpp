#include "common.h"

// 全局变量定义
FILE *log_file = NULL;
bool log_to_console = true;

void log_init(const char *filename, bool enable_console_output)
{
    // 如果之前有打开的文件，先关闭
    if (log_file)
    {
        fclose(log_file);
        log_file = NULL;
    }

    // 如果提供了文件名，打开日志文件
    if (filename)
    {
        log_file = fopen(filename, "w");
        if (!log_file)
        {
            fprintf(stderr, "Warning: Failed to open log file '%s'\n", filename);
        }
    }

    // 设置是否输出到控制台
    log_to_console = enable_console_output;
}

void log_close()
{
    if (log_file)
    {
        fclose(log_file);
        log_file = NULL;
    }
}
