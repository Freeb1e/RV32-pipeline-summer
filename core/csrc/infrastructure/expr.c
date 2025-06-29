/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include <common.h>
#include <memory.h>
#include <cpu.h>

#define MAX_TOKEN 128
enum {
  TK_NOTYPE = 256, TK_EQ,

  /* TODO: Add more token types */
  TK_DEC, TK_HEX, TK_REG, TK_NEQ, TK_GE, TK_LE, TK_GT, TK_LT, TK_AND, TK_OR, TK_DEREF, TK_NEG
};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */
  {" +", TK_NOTYPE},    // spaces
  {"==", TK_EQ},        // equal
  {"!=", TK_NEQ},       // not equal
  {">=", TK_GE},        // greater or equal
  {"<=", TK_LE},        // less or equal
  {">", TK_GT},         // greater
  {"<", TK_LT},         // less
  {"&&", TK_AND},   // and
  {"\\|\\|", TK_OR},    // or
  {"0x[0-9a-fA-F]+", TK_HEX}, // hex numbers
  {"[0-9]+", TK_DEC},   // decimal numbers
  {"\\$[0-9a-zA-Z]+", TK_REG}, // register
  {"\\+", '+'},         // plus
  {"-", '-'},           // minus
  {"\\*", '*'},         // multiply
  {"\\/", '/'},         // divide
  {"\\(", '('},         // left paran
  {"\\)", ')'},         // right paran
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

void free_regex(){
  int i;
  for (i = 0; i < NR_REGEX; i ++) {
    regfree(&re[i]);
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[MAX_TOKEN] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        if(nr_token>=MAX_TOKEN){
          printf("Too many tokens~\n");
          return false;
        }

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        if(rules[i].token_type == TK_NOTYPE){
          break;
        }
        
        /* record the token */
        tokens[nr_token].type = rules[i].token_type;
        if(substr_len >= MAX_TOKEN){
          Log("Token too long: %.*s. Cut to %.*s\n", substr_len, substr_start, MAX_TOKEN-1, substr_start);
          //cut
          substr_len = MAX_TOKEN-1;
        }
        strncpy(tokens[nr_token].str, substr_start, substr_len);
        tokens[nr_token].str[substr_len] = '\0';
        nr_token++;
        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}
enum {PAREN_INVALID, PAREN_MATCH, PAREN_DISMATCH};
int check_parenthesis(Token *p, Token *q){
  int i = 0;
  int dismatch_flag = 0;
  for(int j=0;p+j<q;j++){
    if((p+j)->type == '('){
      i=i+1;
    }
    if((p+j)->type == ')'){
      i=i-1;
    }
    if(i==0&&p+j!=q-1){
      dismatch_flag = 1;
    }
  }
  if(i!=0){
    return PAREN_INVALID;
  }else if(p->type!='('||(q-1)->type!=')'||dismatch_flag){
    return PAREN_DISMATCH;
  }else{
    return PAREN_MATCH;
  }
}
Token* FindMainOP(Token* p, Token* q, bool* is_binary){
  int i;
  int mainoptype = 0;
  int mainoppos = -1;
  for(i=0;p+i<q;i++){
    switch((p+i)->type){
      case '(':
        {
          int layer = 1;
          while(layer>0){
            i++;
            switch((p+i)->type){
              case '(':
                layer++;
                break;
              case ')':
                layer--;
                break;
            }
          }
        }
        break;
      case ')':
        Assert(0,"parenthesis dismatch\n");
        break;
      case TK_DEREF: case TK_NEG:
        if(mainoptype == 0){
          mainoptype = (p+i)->type;
          mainoppos = i;
          *is_binary = false;
        }
        break;
      case '*': case '/':
        if(mainoptype==0|| mainoptype==TK_DEREF || mainoptype==TK_NEG || mainoptype=='*'|| mainoptype=='/'){
          mainoptype = (p+i)->type;
          mainoppos = i;
          *is_binary = true;
        }
        break;
      case '+': case '-':
        if(mainoptype==0 || mainoptype==TK_DEREF || mainoptype==TK_NEG || mainoptype=='*' || mainoptype=='/' || mainoptype=='+' || mainoptype=='-'){
          mainoptype = (p+i)->type;
          mainoppos = i;
          *is_binary = true;
        }
        break;
      case TK_EQ: case TK_NEQ: case TK_GE: case TK_LE: case TK_GT: case TK_LT:
        if(mainoptype==0 || mainoptype==TK_DEREF || mainoptype==TK_NEG || mainoptype=='*' || mainoptype=='/' || mainoptype=='+' || mainoptype=='-' || mainoptype==TK_EQ || mainoptype==TK_NEQ || mainoptype==TK_GE || mainoptype==TK_LE || mainoptype==TK_GT || mainoptype==TK_LT){
          mainoptype = (p+i)->type;
          mainoppos = i;
          *is_binary = true;
        }
        break;
      case TK_AND: case TK_OR:
        if(mainoptype==0 || mainoptype==TK_DEREF || mainoptype==TK_NEG || mainoptype=='*' || mainoptype=='/' || mainoptype=='+' || mainoptype=='-' || mainoptype==TK_EQ || mainoptype==TK_NEQ || mainoptype==TK_GE || mainoptype==TK_LE || mainoptype==TK_GT || mainoptype==TK_LT || mainoptype==TK_AND || mainoptype==TK_OR){
          mainoptype = (p+i)->type;
          mainoppos = i;
          *is_binary = true;
        }
        break;
    }
  }
  return p+mainoppos;
}

__attribute__((unused)) static void print_expr (Token* p, Token* q) {
  printf("Evaluating:");
  for(int i=0;p+i<q;i++){
    switch((p+i)->type){
      case '+': case '-': case '*': case '/': case '(': case ')':
      printf("%c",(p+i)->type);
      break;
      case TK_DEC: case TK_HEX: case TK_REG:
      printf("%s",(p+i)->str);
      break;
      case TK_EQ:
      printf("==");
      break;
      case TK_NEQ:
      printf("!=");
      break;
      case TK_GE:
      printf(">=");
      break;
      case TK_LE:
      printf("<=");
      break;
      case TK_GT:
      printf(">");
      break;
      case TK_LT:
      printf("<");
      break;
      case TK_AND:
      printf("&&");
      break;
      case TK_OR:
      printf("||");
      break;
      case TK_DEREF:
      printf("*");
      break;
      case TK_NEG:
      printf("-");
      break;
      default:
        assert(0);
    }
  }
  printf("\n");
}
enum {PAREN_ERR=1, BADEXPR_ERR, MAINOP_ERR, UNDEF_OP, REG_ERR, UNKNOWN_ELEMENT_ERR};
uint32_t eval(Token* p, Token* q, int *errflag){
  #ifdef EXPR_DEBUG
  print_expr(p,q);
  #endif

  if(p+1>q){
    //bad expression
    *errflag = BADEXPR_ERR;
    return 0;
  }
  else if(p+1==q){
    /* in this case, p refers to a heximal number, a decimal number, or a register */
    int num;
    if(p->type == TK_DEC){
      num = strtoul(p->str, NULL, 10);
      #ifdef EXPR_DEBUG
      printf("this is a decimal number:%u\n", num);
      #endif
    }else if(p->type == TK_HEX){
      num = strtoul(p->str, NULL, 16);
      #ifdef EXPR_DEBUG
      printf("this is a heximal number:%u\n", num);
      #endif
    }else if(p->type == TK_REG){
      bool success = true;
      num = reg_str2val(p->str+1);
      #ifdef EXPR_DEBUG
      printf("this is a register:%u\n", num);
      #endif
    }else{
      num = 0;
      *errflag = UNKNOWN_ELEMENT_ERR;
    }
    return num;
  }else {
    int ret_val;
    /*Check that the expression is enclosed in parentheses*/
    int ret = check_parenthesis(p,q);
    switch(ret){
      case PAREN_INVALID:
        *errflag = PAREN_ERR;
        return 0;
      case PAREN_MATCH: 
        #ifdef EXPR_DEBUG
        printf("remove parentheses\n");
        #endif
        ret_val = eval(p+1, q-1, errflag);
        return ret_val;
    }
    
    /* find the main operator*/
    bool is_binary;
    Token* pos = FindMainOP(p,q, &is_binary);
    if(pos < p){
      *errflag = MAINOP_ERR;
      return 0;
    }
    #ifdef EXPR_DEBUG
    if(strlen(pos->str)==0) printf("main operator %c found at %d\n", pos->type, (int)(pos-p));
    else printf("main operator %s found at %d\n", pos->str, (int)(pos-p));
    #endif

    /*evaluate expression recursively accroding to the main operator*/
    uint32_t val_right = eval(pos+1, q, errflag);
    if(*errflag!=0) return 0;
    if(!is_binary){
      /*the operator is unary*/
      if(pos->type==TK_NEG){
        ret_val = -val_right;
        #ifdef EXPR_DEBUG
        printf("excuting operation: -%u = %u\n", val_right, ret_val);
        #endif
        return ret_val;
      }else if(pos->type == TK_DEREF){
        ret_val = paddr_read(val_right, 4);
        #ifdef EXPR_DEBUG
        printf("excuting operation: *%u = %u\n", val_right, ret_val);
        #endif
        return ret_val;
      }
    }

    uint32_t val_left = eval(p, pos, errflag);
    if(*errflag!=0) return 0;
    switch(pos->type){
      case '+':
        ret_val = val_left+val_right;
        break;
      case '-':
        ret_val = val_left-val_right;
        break;
      case '*':
        ret_val = val_left*val_right;
        break;
      case '/':
        ret_val = val_left/val_right;
        break;
      case TK_EQ:
        ret_val = val_left==val_right;
        break;
      case TK_NEQ:
        ret_val = val_left!=val_right;
        break;
      case TK_GE:
        ret_val = val_left>=val_right;
        break;
      case TK_LE:
        ret_val = val_left<=val_right;
        break;
      case TK_GT:
        ret_val = val_left>val_right;
        break;
      case TK_LT:
        ret_val = val_left<val_right;
        break;
      case TK_AND:
        ret_val = val_left&&val_right;
        break;
      case TK_OR:
        ret_val = val_left||val_right;
        break;
      default:
        *errflag = UNDEF_OP;
        return 0;
    }
    #ifdef EXPR_DEBUG
    if(strlen(pos->str)==0) printf("executing operation: %u %c %u = %u\n", val_left, pos->type, val_right, ret_val);
    else printf("executing operation: %u %s %u = %u\n", val_left, pos->str, val_right, ret_val);
    #endif
    return ret_val;
  }
}


word_t expr(char *e, bool *success) {
  init_regex();
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* Check the token '*' and '-' */
  for(int i=0;i<nr_token;i++){
    if(tokens[i].type=='*' && (i==0 || !((tokens+i-1)->type == TK_DEC || 
                                         (tokens+i-1)->type == TK_HEX || 
                                         (tokens+i-1)->type == TK_REG ||
                                         (tokens+i-1)->type == ')'))){
      tokens[i].type = TK_DEREF;
    }
    if(tokens[i].type=='-' && (i==0 || !((tokens+i-1)->type == TK_DEC ||
                                         (tokens+i-1)->type == TK_HEX ||
                                         (tokens+i-1)->type == TK_REG ||
                                         (tokens+i-1)->type == ')'))){
      tokens[i].type = TK_NEG;
    }
  }

  Token* p = tokens;
  Token* q = p+nr_token;
  int token_err = 0;
  uint32_t result = eval(p,q,&token_err);
  if(token_err!=0){
    *success = false;
    switch(token_err){
      case PAREN_ERR:
        printf("parenthesis invalid\n");
        break;
      case UNDEF_OP:
        printf("undefined operation\n");
        break;
      case BADEXPR_ERR:
        printf("syntax error\n");
        break;
      case MAINOP_ERR:
        printf("cannot find main operator\n");
        break;
      case REG_ERR:
        printf("register not found\n");
        break;
      case UNKNOWN_ELEMENT_ERR:
        printf("unknown element\n");
        break;
    }
    return 0;
  }
  *success = true;
  return result;
}
