#include <common.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <elf.h>
#include <sys/mman.h>
#include <sys/stat.h>

extern void Cget_reg(int addr, int* reg_data);

typedef struct func_symbol{
    char *name;
    uint32_t addr;
    uint32_t size;
}func_symbol;

static func_symbol *func_symtab = NULL;
int func_num = 0;

static int ftrace_enable = false;
void ftrace_set(int enable) {
  ftrace_enable = enable;
}
int num_of_func_calls = 0;

void init_trace(const char* elf_file){
    if (elf_file == NULL) {
        Log("FTrace: %s",ANSI_FMT("OFF", ANSI_COLOR_RED));
        ftrace_set(false);
        return;
    }

    int fd = open(elf_file, O_RDONLY);
    Assert(fd >= 0 , "Can not open '%s'", elf_file);
    struct stat st;
    int ret = fstat(fd, &st);
    Assert(ret >= 0, "Can not fstat '%s'", elf_file);
    void *data = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    Assert(data != MAP_FAILED, "Can not mmap '%s'", elf_file);
    Assert(memcmp(data, ELFMAG, SELFMAG) == 0, "'%s' is not an ELF file", elf_file);
    close(fd);
    
    Elf32_Ehdr *ehdr = (Elf32_Ehdr *)data; // get the elf header
    Elf32_Shdr *shdr = (Elf32_Shdr *)((char*)data + ehdr->e_shoff); // get the section header table
    Elf32_Shdr *shstrtab_shdr = &shdr[ehdr->e_shstrndx]; // get the section header string table
    const char *shstrtab = (const char *)data + shstrtab_shdr->sh_offset;

    Elf32_Sym *sym = NULL;
    int sym_num = 0;
    const char *strtab = NULL;
    for (int i = 0; i < ehdr->e_shnum; i++) {
        if (shdr[i].sh_type == SHT_SYMTAB) {
            sym = (Elf32_Sym *)((char*)data + shdr[i].sh_offset); // get the symbol table
            sym_num = shdr[i].sh_size / shdr[i].sh_entsize; // get the number of symbols
        }else if(shdr[i].sh_type == SHT_STRTAB && strcmp(".strtab", shstrtab + shdr[i].sh_name) == 0){
            strtab = (char*)data + shdr[i].sh_offset; // get the string table
        }
    }

    for(int i = 0; i < sym_num; i++){
        if(ELF32_ST_TYPE(sym[i].st_info) == STT_FUNC && sym[i].st_shndx != SHN_UNDEF){
            func_num++;
        }
    }

    func_symtab = (func_symbol *)malloc(sizeof(func_symbol) * func_num);
    for (int i=0, j=0; i<sym_num; i++) {
        if (ELF32_ST_TYPE(sym[i].st_info) == STT_FUNC && sym[i].st_shndx != SHN_UNDEF) {
            func_symtab[j].name = strdup(strtab + sym[i].st_name);
            func_symtab[j].addr = sym[i].st_value;
            func_symtab[j].size = sym[i].st_size;
            j++;
        }
    }

    ftrace_set(true);
    Log("Ftrace: %s",ANSI_FMT("ON", ANSI_COLOR_GREEN));
}

void where_am_I(vaddr_t addr, char *func_name, int len){
    for(int i = 0; i < func_num; i++){
        if(addr >= func_symtab[i].addr && addr < func_symtab[i].addr + func_symtab[i].size){
            snprintf(func_name, len, "%s", func_symtab[i].name);
            return;
        }
    }
    snprintf(func_name, len, "???");
    return;
}

void ftrace_decode(int rd, int rs, vaddr_t pc, vaddr_t dnpc){
  char msg[256];
  char func_name[128];
  if(rd == 1){ //func call
    where_am_I(dnpc, func_name, 128);
    char *p_msg = msg;
    p_msg += snprintf(p_msg, sizeof(msg), FMT_WORD ":", pc);
    for(int i=0;i<num_of_func_calls;i++){
      *(p_msg++) = ' ';
      *(p_msg++) = ' ';
    }
    p_msg += snprintf(p_msg, sizeof(msg) - (p_msg - msg), "call [%s@" FMT_WORD "]", func_name, dnpc);
    *(p_msg++) = '\0';
    Log("%s", msg);
    num_of_func_calls++;
  }else if(rd == 0 && rs == 1){//func return
    char *p_msg = msg;
    num_of_func_calls--;
    where_am_I(pc, func_name, 128);
    p_msg += snprintf(p_msg, sizeof(msg), FMT_WORD ":", pc);
    for(int i=0;i<num_of_func_calls;i++){
      *(p_msg++) = ' ';
      *(p_msg++) = ' ';
    }
    p_msg += snprintf(p_msg, sizeof(msg) - (p_msg - msg), "ret [%s]", func_name);
    *(p_msg++) = '\0';
    Log("%s", msg);
  }
}

void ftrace(vaddr_t pc, uint32_t inst){
  if(!ftrace_enable){
    return;
  }
  bool is_jal, is_jalr;
  is_jal = (inst & 0x7F) == 0x6F;
  is_jalr = (inst & 0x7067) == 0x67;
  if(!(is_jal || is_jalr)){
    return;
  }
  int rd, rs;
  vaddr_t dnpc;

  if(is_jal){
    uint32_t imm = ((SEXT(BITS(inst, 31, 31), 1) << 20) | (BITS(inst, 30, 21) << 1) | (BITS(inst, 20, 20) << 11) | (BITS(inst, 19, 12) << 12));
    rd = (inst >> 7) & 0x1F;
    dnpc = pc + imm;
    ftrace_decode(rd, 0, pc, dnpc);
  }else if(is_jalr){
    rd = (inst >> 7) & 0x1F;
    rs = (inst >> 15) & 0x1F;
    int src;
    Cget_reg(rs, &src);
    uint32_t imm = ((SEXT(BITS(inst, 31, 31), 1) << 11) | (BITS(inst, 30, 20) << 1));
    dnpc = (src + imm) & 0xFFFFFFFE;
    ftrace_decode(rd, rs, pc, dnpc);
  }
}

void free_trace(){
    if(func_symtab != NULL){
        for(int i = 0; i < func_num; i++){
            free(func_symtab[i].name);
        }
        free(func_symtab);
    }
}

#define IRNGBUF_LEN 32
typedef struct iringbuf_unit {
  vaddr_t pc;
  uint32_t inst;
  uint8_t valid;
} iringbuf_unit;
iringbuf_unit iringbuf[IRNGBUF_LEN];
uint32_t iringbuf_ptr = 0;

void write_iringbuf(vaddr_t pc, uint32_t inst) {
  iringbuf[iringbuf_ptr].pc = pc;
  iringbuf[iringbuf_ptr].inst = inst;
  iringbuf[iringbuf_ptr].valid = 1;
  iringbuf_ptr = (iringbuf_ptr + 1) % IRNGBUF_LEN;
}

void display_iringbuf() {
  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  char msg[128];
  char *p;
  for (int i = 0; i < IRNGBUF_LEN; i ++) {
    p = msg;
    uint8_t *inst = (uint8_t *)&iringbuf[i].inst;

    if (iringbuf[i].valid) {
      p += snprintf(p, sizeof(msg) - (p - msg), FMT_WORD ":", iringbuf[i].pc);
      for(int j = 0; j < 4; j ++){
        p += snprintf(p, 4, " %02x", inst[j]);
      }
      for(int j = 0;j < 2; j++){
        *(p++) = '\t';
      }
      disassemble(p, sizeof(msg) - (p - msg), iringbuf[i].pc, inst, 4);
      if(i == iringbuf_ptr-1){
        printf("==>" ANSI_COLOR_RED "%s\n" ANSI_COLOR_RESET, msg);
      }else{
        printf("   ""%s\n", msg);
      }
    }
  }
}