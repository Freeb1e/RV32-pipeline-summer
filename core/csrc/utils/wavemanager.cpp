#define MAX_WAVE_NUM 3
#define MAX_WAVE_SIZE 1000000
#define WAVE_NAME_FORMAT "waveform/jingyeda%d.vcd"

#include <common.h>

VerilatedVcdC *cur_trace;
VerilatedVcdC *wave_traces[MAX_WAVE_NUM];
int cur_wave_idx = 0;
int sim_time = 0;

void SwitchWaveTrace(Vdut *dut)
{
    if (cur_trace)
    {
        cur_trace->close();
        delete cur_trace;
    }
    char wave_name[32];
    sprintf(wave_name, WAVE_NAME_FORMAT, cur_wave_idx);
    wave_traces[cur_wave_idx] = new VerilatedVcdC;
    cur_trace = wave_traces[cur_wave_idx];
    dut->trace(cur_trace, 10);
    cur_trace->open(wave_name);

    cur_wave_idx = (cur_wave_idx + 1) % MAX_WAVE_NUM;
    sim_time = 0;
}

void EvalAndWaveTrace(Vdut *dut)
{
    if (cur_trace == NULL || sim_time >= MAX_WAVE_SIZE)
    {
        SwitchWaveTrace(dut);
    }
    dut->eval();
    cur_trace->dump(sim_time++);
}

void DeinitWaveTrace()
{
    if (cur_trace)
    {
        cur_trace->close();
        delete cur_trace;
    }
}