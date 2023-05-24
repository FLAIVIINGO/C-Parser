#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hash_table.h"
#include "stack.h"

// free all dynamically allocated stuff
//void free_map(HashMap *map) {
//  free(map);
//}

// free a single node
//void free_node(Node *n) {
//  free(n->key);
//  free(n->value);
//  n->next = NULL;
//  free(n);
//}
//
//void free_bucket(LinkedList *bucket) {
//  while(bucket->head != NULL) {
//    Node *tmp = bucket->head->next;
//    free_node(bucket->head);
//    bucket->head = tmp;
//  }
//  free(bucket);
//}

// print elements in hash table
void print(HashMap *map) {
  printf("Symbol      ");
  printf("Data Type    ");
  printf("Type      ");
  printf("Line Number      ");
  printf("\n");
  for(int i = 0; i < map->capacity; i++) {
    if(map->table[i] == NULL) continue;
    Node *tmp = map->table[i]->head;
    while(tmp != NULL) {
      printf("%s        ", tmp->key);
      printf("%s          ", tmp->info->data_type);
      printf("%s  ", tmp->info->type);
      printf("%d", tmp->info->line_no);
      printf("\n");
      tmp = tmp->next;
    }
  }
}

// Initialize the hash map
HashMap *init_hashmap(int capacity) {
  HashMap *map = malloc(sizeof(HashMap));
  map->size = 0;
  map->capacity = capacity;
  map->threshold = (int)(map->capacity * MAX_LOAD);
  // make all values null in table
  //for(int i = 0; i < capacity; i++) {
  //  map->table[i] = NULL;
  //}
  map->table = calloc(capacity, sizeof(LinkedList));
  return map;
}

LinkedList *init_list() {
  LinkedList *list = malloc(sizeof(LinkedList));
  if(list == NULL) {
    fprintf(stderr, "Fatal: failed to create Linked List\n");
    exit(1);
  }
  list->size = 0;
  list->head = NULL;

  return list;
}

void remove_node(char *key, LinkedList *bucket, HashMap *map) {
  Node *tmp = bucket->head;
  if(strcmp(tmp->key, key) == 0) {
    bucket->head = tmp->next;
    bucket->size--;
    map->size--;
    tmp->next = NULL;
    free(tmp);
    return;
  }
  while(tmp->next != NULL) {
    if(strcmp(tmp->next->key, key) == 0) {
      Node *del = tmp->next;
      tmp->next = tmp->next->next;
      del->next = NULL;
      free(del);
      bucket->size--;
      map->size--;
      break;
    }
    tmp = tmp->next;
  }
}

void add_to_bucket(char *key, char *d_t, LinkedList* bucket,
    char *t, int line_no, int args) {
  Node *tmp = bucket->head;
  if(tmp == NULL) {
    bucket->head = create_node(key,d_t,t,line_no,args);
  }
  else {
    while(tmp->next != NULL) {
      tmp = tmp->next;
    }
    tmp->next = create_node(key,d_t,t,line_no,args);
  }
  // increase the buckets size
  bucket->size++;
}

Node *create_node(char *k, char *d_t, char *t, int line_no, int args) {
  // declare node variables
  Node *node = malloc(sizeof(Node));
  if(node == NULL) {
    fprintf(stderr, "Fatal: failed to create Node struct\n");
    exit(2);
  }
  node->key = NULL;
  node->next = NULL;
  node->info = malloc(sizeof(Symbol));
  if(node->info == NULL) {
    fprintf(stderr, "Fatal: failed to create Symbole struct\n");
    exit(3);
  }
  node->info->id_name = NULL;
  node->info->data_type = NULL;
  node->info->type = NULL;
  node->info->line_no = 0;
  node->info->args = -1;

  // initialize key value pairs and null terminate
  size_t key_len = strlen(k);
  size_t d_t_len = strlen(d_t);
  size_t t_len = strlen(t);
  node->key = malloc(key_len + 1);
  node->info->id_name = malloc(key_len + 1);
  node->info->data_type = malloc(d_t_len + 1);
  node->info->type = malloc(t_len + 1);
  node->info->line_no = line_no;
  memcpy(node->key,k,key_len);
  memcpy(node->info->id_name,k,key_len);
  memcpy(node->info->data_type,d_t,d_t_len);
  memcpy(node->info->type,t,t_len);
  node->key[key_len] = '\0';
  node->info->id_name[key_len] = '\0';
  node->info->data_type[d_t_len] = '\0';
  node->info->type[t_len] = '\0';

  return node;
}

void resize_table(HashMap *map) {
  // re-calculate capacity and threshold
  int old_cap = map->capacity;
  map->capacity *= 2;
  map->threshold = (int)(map->capacity * MAX_LOAD);
  // create new table
  LinkedList **new_table = calloc(map->capacity, sizeof(LinkedList));
  for(int i = 0; i < old_cap; i++) {
    if(map->table[i] != NULL) {
      // loop through bucket and assign to new bucket
      Node *tmp = map->table[i]->head;
      while(tmp != NULL) {
        int bucket_idx = hash(tmp->key, map->capacity);
        LinkedList *bucket = new_table[bucket_idx];
        if(bucket == NULL) {
          new_table[bucket_idx] = init_list();
          bucket = new_table[bucket_idx];
        }
        add_to_bucket(tmp->key,tmp->info->data_type,
            bucket,tmp->info->type,tmp->info->line_no,tmp->info->args);
        tmp = tmp->next;
      }
      // free the current bucket
      //free_bucket(map->table[i]);
    }
  }
  free(map->table);
  map->table = new_table;
}

// Put and add a key value pair in the hashtable
// Returns the value that was inserted inserted if it existed, else NULL
Symbol *put(char* key, char *d_t, char* t, int line_no, int args, HashMap *map) {
  if(key == NULL) {
    fprintf(stderr, "Fatal: Null value passed in put method\n");
    exit(3);
  }
  // get hash val of key
  int bucket_idx = hash(key, map->capacity);
  LinkedList *bucket = map->table[bucket_idx];
  // if bucket is null, make a new list
  if(bucket == NULL) {
    bucket = init_list();
  }
  // condition to seek existing entry if it exists
  Node *existent_node = seek_bucket_entry(bucket_idx, key, bucket);
  if(existent_node == NULL) {
    // add to linked list
    add_to_bucket(key,d_t, bucket,t,line_no,args);
    map->table[bucket_idx] = bucket;
    if(++map->size > map->threshold) {
      //printf("resize\n");
      resize_table(map);
    }
    // resize if needed
    return NULL;
  }
  else {
    //printf("entry exists, update value\n");
    Symbol* old_val = existent_node->info;
    existent_node->info->id_name = key;
    existent_node->info->data_type = d_t;
    existent_node->info->type = t;
    existent_node->info->line_no = line_no;
    existent_node->info->args = args;
    return old_val;
  }
}

Node *seek_bucket_entry(int idx, char *key, LinkedList *bucket) {
  if(bucket == NULL) return NULL;
  // check status of head, if NULL return NULL to add node
  if(bucket->head == NULL) {
    return NULL;
  }
  // if we reach here, the list exists, traverse to see if entry exists
  // and return the node, else return null
  Node *tmp = bucket->head;
  while(tmp != NULL) {
    int res = 0;
    res = strcmp(key, tmp->key);
    if(res == 0) {
      return tmp;
    }
    tmp = tmp->next;
  }
  return NULL;
}

Node *get(char *key, HashMap *map) {
  if(key == NULL) return NULL;
  int bucket_idx = hash(key,map->capacity);
  Node *ret = seek_bucket_entry(bucket_idx, key, map->table[bucket_idx]);
  if(ret != NULL) return ret;
  return NULL;
}

Symbol *remove_(char *key, HashMap *map) {
  int bucket_idx = hash(key, map->capacity);
  Node *node = seek_bucket_entry(bucket_idx, key, map->table[bucket_idx]); 
  if(node != NULL) {
    LinkedList *bucket = map->table[bucket_idx];
    remove_node(key, bucket, map);
    return node->info;
  }
  return NULL;
}

// Hashing Function that deals with integer overflow
int hash(char* key, int capacity) {
  int hash_val = 0;
  int key_len = strlen(key);
  
  for(int i = 0; i < key_len; i++) {
    hash_val = 37 * hash_val + key[i];
  }

  return (hash_val & 0x7FFFFFFF) % capacity;
}


