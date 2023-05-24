#ifndef STACK
#define STACK
#include "hash_table.h"

typedef struct Scope {
  char *name;
  HashMap *table;
  int args;
  struct Scope *next;
}Scope;

typedef struct Stack {
  int size;
  Scope *head;
}Stack;

Stack *init_stack();

int empty(Stack*);
Scope *pop(Stack*);
Scope *push(Stack*,Scope*);


#endif
