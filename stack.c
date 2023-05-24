#include <stdio.h>
#include <stdlib.h>
#include "hash_table.h"
#include "stack.h"

Stack *init_stack() {
  Stack *st = malloc(sizeof(Stack));
  if(st == NULL) {
    fprintf(stderr, "Fatal error with Stack malloc\n");
    exit(1);
  }
  st->size = 0;
  st->head = NULL;

  return st;
}

int empty(Stack *st) {
  if(st->size == 0) return 1;
  return 0;
}

Scope *pop(Stack *st) {
  if(empty(st)) return NULL;
  Scope *curr = st->head;
  st->head = st->head->next;
  st->size--;
  return curr;
}

Scope *push(Stack *st, Scope *sc) {
  if(st == NULL) return NULL;
  if(sc == NULL) return NULL;
  sc->next = st->head;
  st->head = sc;
  st->size++;
}

