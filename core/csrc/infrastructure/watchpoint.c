#include "sdb.h"

#define NR_WP 32

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].prev = (i == 0 ? NULL : &wp_pool[i - 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */

WP* new_wp(){
  WP* temp;
  
  if(free_==NULL) Assert(0,"no free watchpoint in pool");
  if(head==NULL){
    head = free_;
    free_ = free_->next;
    head->next = NULL;
    head->prev = NULL;
  }else{
    temp = head;
    head = free_;
    free_ = free_->next;
    head->next = temp;
    head->prev = NULL;
    temp->prev = head;
  }
  return head;
}

void free_wp(WP* wp){
  if(wp==head){
    head = head->next;
    if(head!=NULL) head->prev = NULL;
  }else{
    wp->prev->next = wp->next;
    wp->next->prev = wp->prev;
  }
  wp->next = free_;
  wp->prev = NULL;
  free_->prev = wp;
  free_ = wp;
}

bool check_wp(){
  WP* temp = head;
  bool is_changed = false;
  while(temp!=NULL){
    bool success;
    word_t val = expr(temp->expr, &success);
    if(!success){
      printf("Invalid expression:%s\n",temp->expr);
      return false;
    }
    if(val!=temp->val){
      printf("Watchpoint %d: %s\n",temp->NO,temp->expr);
      printf("Old value = %u\n",temp->val);
      printf("New value = %u\n",val);
      temp->val = val;
      is_changed = true;
    }
    temp = temp->next;
  }
  return is_changed;
}

void delete_wp(uint32_t NO){
  WP* temp = head;
  while(temp!=NULL){
    if(temp->NO == NO){
      free_wp(temp);
      return;
    }
    temp = temp->next;
  }
  printf("No watchpoint %d\n",NO);
}

void print_wp(){
  //print the watchpoint list as gdb format
  WP* temp = head;
  printf("Num\tWhat\n");
  while(temp!=NULL){
    printf("%d\t%s\n",temp->NO,temp->expr);
    temp = temp->next;
  }
  
}