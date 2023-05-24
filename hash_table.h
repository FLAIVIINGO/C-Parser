#ifndef HASH_TABLE
#define HASH_TABLE

#define DFLT_CAP 8
#define MAX_LOAD 0.75

typedef struct Symbol {
  char *id_name;
  char *data_type;
  char *type;
  int line_no;
  int args;
}Symbol;

typedef struct Node {
  char *key;
  struct Symbol *info;
  struct Node *next;
}Node;

typedef struct LinkedList {
  int size;
  Node *head;
}LinkedList;

typedef struct HashMap {
  int size;
  int capacity;
  int threshold;
  double max_load;
  LinkedList **table;
}HashMap;

int hash(char*,int);
HashMap *init_hashmap(int);
void free_map(HashMap*);
Node *create_node(char*,char*,char*,int,int);
void free_node(Node*);
Symbol *put(char*,char*,char*,int,int,HashMap*);
Node *seek_bucket_entry(int,char*,LinkedList*);
void add_to_bucket(char*,char*,LinkedList*,char*,int,int);
void resize_table(HashMap*);
void print(HashMap*);
void free_bucked(LinkedList*);
Node *get(char*,HashMap*);
Symbol *remove_(char*,HashMap*);
void remove_node(char*,LinkedList*,HashMap*);

#endif
