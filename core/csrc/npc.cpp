#include <cpu.h>
#include <getopt.h>
#include <sdb.h>

extern int sim_time;
extern Vnpc *dut;
extern CPU_state state;
extern VerilatedVcdC *m_trace;
extern char *img_file;
int is_deinit = 0;

/* statistics */
extern uint32_t nr_inst;
extern uint32_t nr_cycle;

/* memory */
long load_img();
uint32_t paddr_read(uint32_t addr);
/* sdb */
void init_sdb();
void free_sdb();
void sdb_mainloop();
void sdb_set_batch_mode();
/* disasm */
void init_disasm();
/* difftest */
void init_difftest(char *ref_so_file, long img_size, int port);
/* trace */
void display_iringbuf();



char *elf_file = NULL;
char *so_file = NULL;
long img_size;

void ebreak(){
    int ret_code;
    uint32_t pc;
    Cget_reg(10, &ret_code);
    Cget_pc_inst(&pc, NULL);
    stop(ret_code, pc);
}

void parse_args(int argc, char** argv){
    static struct option long_options[] = {
        {"image", required_argument, 0, 'i'},
        {"batch", no_argument, 0, 'b'},
        {"elf", required_argument, 0, 'e'},
        {"diff", required_argument, 0, 'd'},
        {0, 0, 0, 0}
    };
    int o;
    while((o = getopt_long(argc, argv, "i:be:d:", long_options, NULL)) != -1){
        switch(o){
            case 'i':
                img_file = optarg;
                break;
            case 'b':
                sdb_set_batch_mode();
                break;
            case 'e':
                elf_file = optarg;
                break;
            case 'd':
                so_file = optarg;
                break;
            default:
                break;
        }
    }
}

static void welcome(){

    #ifdef CONFIG_ITRACE
    Log("ITrace: %s", ANSI_FMT("ON", ANSI_COLOR_GREEN));
    #else
    Log("ITrace: %s", ANSI_FMT("OFF", ANSI_COLOR_RED));
    #endif

    #ifdef CONFIG_MTRACE
    Log("MTrace: %s", ANSI_FMT("ON", ANSI_COLOR_GREEN));
    #else
    Log("MTrace: %s", ANSI_FMT("OFF", ANSI_COLOR_RED));
    #endif

    printf("Welcome to %s-NPC!\n", ANSI_FMT("riscv32", ANSI_COLOR_YELLOW ANSI_BG_RED));
    printf("For help, type \"help\"\n");

}

void initialize(int argc, char** argv){
    parse_args(argc, argv);

    cpu_init("npc.vcd");

    img_size = load_img();

    init_trace(elf_file);

    init_sdb();

    init_disasm();

    init_difftest(so_file, img_size, 1);

    reset(5);

    welcome();

    state = RUNNING;
}

void deinitialize(){
    free_sdb();

    free_trace();

    if(!is_deinit) cpu_deinit();
}

void display_error_msg(){
    display_iringbuf();
    cpu_deinit();
    is_deinit = 1;
}

void statistics_display(){
    printf(ANSI_FMT("Statistics:", ANSI_COLOR_CYAN ANSI_BG_GREEN) "\n");
    printf("Instructions executed:%u\n", nr_inst);
    printf("Cycles: %u\n", nr_cycle);
    if(nr_cycle > 0) {
        printf("IPC: %.2f\n", (float)nr_inst / nr_cycle);
    }
}

int main(int argc, char** argv){

    initialize(argc, argv);

    sdb_mainloop();

    deinitialize();

    switch (state) {
        case ABORT:
        printf("Execution aborted\n");
            return 1;
        default:
            return 0;
    }
    return 0;
}
