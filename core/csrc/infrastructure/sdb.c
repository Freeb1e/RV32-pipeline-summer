#include <cpu.h>
#include <memory.h>
#include "sdb.h"

extern CPU_state state;

static int is_batch_mode = false;

void init_regex();
void free_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}
//convert string to integer
static int safe_atoi(char *str, uint32_t* result){
  char *endptr;
  long val = strtol(str,&endptr,10);

  if(*endptr != '\0'){
    return -1;
  }

  *result = val;
  return 0;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_si(char *args){
  if(args==NULL){
    cpu_exec(1);
  }else{
    uint32_t n;
    int ret = safe_atoi(args, &n);
    if(ret<0){
      printf("%s is not pure number!\n", args);
    }else{
      cpu_exec(n);
    }
  }
  return 0;
}


static int cmd_q(char *args) {
  if(state!=ABORT) state = QUIT;
  return -1;
}
static int cmd_help(char *args);

static int cmd_info(char *args){
  if(args==NULL){
    printf("Blank arg for info is not valid. Try\"help info\"\n");
  }else if(strcmp(args, "r")==0||strcmp(args, "registers")==0||strcmp(args, "register")==0||strcmp(args, "reg")==0){
    reg_display();
  }else if(strcmp(args, "w")==0||strcmp(args, "watchpoint")==0){
    print_wp();
  }else{
    printf("Undefined info command:%s. Try \"help info\"\n",args);
  }
  return 0;
}

static int cmd_x(char *args){
  uint32_t N;
  uint32_t addr;
  args = strtok(NULL, " ");
  if(args==NULL){
    printf("missing N args. Try \"help x\"\n");
  }else if(sscanf(args,"%d",&N)!=1){
    printf("Invalid N args. Try \"help x\"\n");
  }

  args = strtok(NULL, " ");
  if(args==NULL){
    printf("missing EXPR args. Try \"help x\"\n");
  }
  bool success = true;
  addr = expr(args, &success);
  if(!success){
    printf("Invalid EXPR args.");
  }
  word_t data;
  for (int i = 0; i < N; i++) {
    data = vaddr_read(addr + i, 1);
    if (i % 4 == 0) {
      printf("\n0x%08X: ", addr + i);
    }
    printf("%02X ", data);
  }
  printf("\n");
  return 0;
}

static int cmd_p(char *args){
  if(args==NULL){
    return 0;
  }else{
    bool success;
    word_t result;
    result = expr(args, &success);
    if(!success){
      printf("Invalid expression:%s\n",args);
      return 0;
    }
    printf("%u\n",result);
  }
  return 0;
}

static int cmd_w(char *args){
  WP* wp = new_wp();
  if(args==NULL){
    printf("Invalid w usage. Try \"help w\"\n");
  }else{
    bool success;
    wp->val = expr(args, &success);
    if(!success){
      printf("Invalid expression:%s\n",args);
      free_wp(wp);
      return 0;
    }
    strcpy(wp->expr, args);
    printf("Watchpoint %d: %s\n",wp->NO,wp->expr);
  }
  return 0;
}

static int cmd_d(char *args){
  if(args==NULL){
    printf("Invalid d usage. Try \"help d\"\n");
  }else{
    uint32_t NO;
    int ret = safe_atoi(args, &NO);
    if(ret<0){
      printf("Invalid NO args. Try \"help d\"\n");
      return 0;
    }
    delete_wp(NO);
    printf("Watchpoint %d deleted\n",NO);
  }
  return 0;
}
static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si", "Make the program pause after executing N instructions. When N is not specified, it defaults to 1", cmd_si},
  { "info", "Print the state of program", cmd_info},
  { "x", "Examine memory:x N EXPR\nEXPR is an expression for the memory address to examine.\nN is the number of bytes to output.", cmd_x},
  { "p", "usage:p EXPR\n figure out the result of EXPR", cmd_p},
  { "w", "Set a watchpoint for an expression. When the value of expression change, the program pause. ", cmd_w },
  { "d", "Delete a watchpoint", cmd_d },
};

#define NR_CMD ARRLEN(cmd_table)
static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    // extern void sdl_clear_event_queue();
    // sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}

void free_sdb() {
  free_regex();
}