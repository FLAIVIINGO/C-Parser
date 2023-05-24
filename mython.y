%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hash_table.h"
#include "stack.h"

Scope *enterScope(char*);
Scope *exitScope(char*,char*);
int lookup(char*);
HashMap *map;
extern int lineno;
Stack *stack;
int num_param = 0;
int num_args = 0;
HashMap *lookup_table;


%}
%token DEF_T FED_T <type>IF_T FI_T ELSE_T <type>WHILE_T ELIHW_T
%token INPUT_T <type>PRINT_T RETURN_T 
%token <id>ID <id>INT_LIT
%token RP LP RB LB COMMA COLON
%token ASSIGN TRUE_T FALSE_T 
%nonassoc OR
%nonassoc AND 
%nonassoc LT LE GT GE EQ NE
%right NOT
%left PLUS MINUS
%left MULT 

%union {
  char* id;
  char* type;
}

%type <type>print_stmt
%type <type>return_stmt
%type <type>exp
%type <type>statements
%type <type>statement
%type <type>param_list
%type <type>assignment_stmt
%type <type>input_stmt
%type <type>condition_stmt
%type <type>while_stmt
%type <type>call_stmt

%%
program		      :	     function_list end_list
		            ;

function_list	  :	     function_list function
		            |	
		            ;

function        :       DEF_T ID LP 
                        { if(lookup($2)) {
                            printf("Line %d: Duplicate function in scope "
                                "%s\n",lineno,$2);
                          }
                          //printf("Entering scope %s\n", $2);
                          enterScope($2);
                        }
                        parameters
                        RP COLON statements FED_T
                        {
                          exitScope($2,$8);
                        } 
                |       DEF_T ID LP RP COLON 
                        {
                          if(lookup($2)) {
                            printf("Line %d: Duplicate function in scope: "
                                "%s\n",lineno,$2);
                          }
                          enterScope($2);
                        } 
                        statements FED_T
                        { //printf("exit scope %s\n", stack->head->name);
                          exitScope($2,$7); //put($2,$7,"Function\0",lineno,map);
                          //printf("stack name: %s\n", stack->head->name);
                          //Node *tmp = get($2,stack->head->table);
                          //printf("tmp: %s type: %s\n", tmp->key, tmp->info->data_type);
                        }
		            ;

parameters	    :	      parameters COMMA ID {//printf("parameter %s in %s\n",$3,stack->head->name);
                                              num_param++;
                                              if(!lookup($3)) {
                                                put($3,"int\0","Variable\0",lineno,-1,stack->head->table);
                                              }
                                              else {
                                                printf("Line %d: Duplicate "
                                                    "variable in scope: %s\n",
                                                    lineno,$3);
                                              }
                                            }
		            |	      parameters COMMA ID LB RB 
                            {
                              num_param++;
                              put($3,"int\0","Array\0",lineno,-1,stack->head->table);
                            }
		            |	      ID {//printf("parameter: %s in %s\n",$1,stack->head->name); 
                            num_param++;
                            // add parameter to local scope
                            if(!lookup($1)) {
                              put($1,"int\0","Variable\0",lineno,-1,stack->head->table);
                            }
                            else {
                              printf("Line %d: Duplicate variable in scope: "
                                  "%s\n",lineno,$1);
                            }
                           }	
		            |	      ID LB RB {//printf("param %s[] in %s\n",$1,stack->head->name);
                                   num_param++;
                                   put($1,"int\0","Array\0",lineno,-1,stack->head->table);
                                 }
		            ;

statements	    :	      statements statement {$$ = $2;}
		            |     	statement {$$ = $1;}
		            ;
statement       :       assignment_stmt
                |       print_stmt
                |       input_stmt
                |       condition_stmt
                |       while_stmt
                |       call_stmt
		            |	      return_stmt {$$ = $1;}
                ;

return_stmt     :       RETURN_T exp {//printf("Return type %s for %s scope\n",$2,stack->head->name);
                                      // possible solution is to store the type of return func now
                                      if(lookup(stack->head->name)) {
                                        Node *tmp = get(stack->head->name,lookup_table);
                                        //printf("***************%s\n",tmp->info->data_type);
                                        put(tmp->info->id_name,$2,tmp->info->type,tmp->info->line_no,
                                            tmp->info->args,lookup_table);
                                        //Node *tmp2 = get(stack->head->name,lookup_table);
                                        //printf("@@@@@@@@@@@@%s\n",tmp->info->data_type);
                                      }
                                      $$ = $2;
                                     }
                |       RETURN_T {$$ = "void\0";}
                ;

call_stmt       :       ID LP RP {//printf("%s()\n",$1);
                                  if(lookup($1)) {
                                    // do something
                                    // printf("look up success\n");
                                  }
                                  else {
                                    // lots to do, just display message
                                    printf("Line %d: Function not declared: "
                                        "%s\n",lineno,$1);
                                  }
                                 }
                |       ID LP param_list RP 
                        {
                          //printf("%s(%s)\n",$1,$3);
                          Node *tmp = get($1,stack->head->table);
                          if(tmp != NULL) {
                            //printf("%s args: %d\n",$1,tmp->info->args);
                            //printf("number of parameters %d\n",num_args);
                            if(tmp->info->args != num_args) {
                              printf("Line %d: Illegal number of parameters: "
                                  "function: %s\n",lineno,$1);
                            }
                          }
                          if(!lookup($1)) {
                            printf("Line %d: Function not declared: %s\n",
                                lineno,$1);
                          }
                          if(strcmp($3,"bool") == 0 || strcmp($3,"unknown")
                              == 0) {
                            printf("Line %d: Illegal parameter type: Integer "
                                "or array expected on function : %s\n",lineno,
                                $1);
                          }
                          num_args = 0;
                        }
                ;

assignment_stmt :       ID ASSIGN exp 
                        {
                          //printf("%s ASSIGN %s\n",$1,$3);
                          int flag = 0;
                          if(lookup($1)) {
                            Node *node = get($1,lookup_table);
                            if(strcmp(node->info->data_type,$3) != 0) {
                              printf("Line %d: Type mismatch in assignment "
                                  "statement %s = %s\n",lineno,$1,$3);
                              flag = 1;
                            }
                          }
                          if(flag != 1) {
                            put($1,$3,"Variable\0",lineno,-1,stack->head->table);
                          }
                        }
                |       ID LB exp RB ASSIGN exp
                        {//printf("%s[%s] ASSIGN %s\n",$1,$3,$6);
                          if(lookup($1)) {
                            Node *node = get($1,lookup_table);
                            if(strcmp(node->info->type,"Array") != 0) {
                              printf("Line %d: Use of non-array type as an "
                                  "array: %s\n",lineno,$1);
                            }
                          }
                          if(strcmp($3,"bool") == 0 || strcmp($3,"unknown") 
                              == 0) {
                            printf("Line %d: Array indices must be type "
                                "Integers\n",lineno);
                          }
                          if(strcmp($6,"int") != 0) {
                            printf("Line %d: Can only assign integers to "
                                "arrays\n",lineno);
                          }
                        }
                ;

exp             :       exp EQ exp {
                                    if(strcmp($1,"int") == 0 && 
                                      strcmp($3,"int") == 0) {
                                      //$$ = $1;
                                    }
                                    else {
                                      printf("Line %d: Illegal types in "
                                          "expression operator != expects "
                                          "Integer\n",lineno);
                                      //$$ = "int\0";
                                    }
                                    $$ = "bool\0";
                                   }
                |       exp NE exp {
                                    if(strcmp($1,"int") == 0 && 
                                      strcmp($3,"int") == 0) {
                                      //$$ = $1;
                                    }
                                    else {
                                      printf("Line %d: Illegal types in "
                                          "expression operator != expects "
                                          "Integer\n",lineno);
                                      //$$ = "int\0";
                                    }
                                    $$ = "bool\0";
                                   }
                |       exp LT exp {
                                    if(strcmp($1,"int") == 0 && 
                                      strcmp($3,"int") == 0) {
                                      //$$ = $1;
                                    }
                                    else {
                                      printf("Line %d: Illegal types in "
                                          "expression operator < expects "
                                          "Integer\n",lineno);
                                      //$$ = "int\0";
                                    }
                                    $$ = "bool\0";
                                   }
                |       exp LE exp {
                                    if(strcmp($1,"int") == 0 && 
                                      strcmp($3,"int") == 0) {
                                      //$$ = $1;
                                    }
                                    else {
                                      printf("Line %d: Illegal types in "
                                          "expression operator <= expects "
                                          "Integer\n",lineno);
                                      //$$ = "int\0";
                                    }
                                    $$ = "bool\0";
                                   }
                |       exp GT exp {
                                    if(strcmp($1,"int") == 0 && 
                                      strcmp($3,"int") == 0) {
                                      //$$ = $1;
                                    }
                                    else {
                                      printf("Line %d: Illegal types in "
                                          "expression operator > expects "
                                          "Integer\n",lineno);
                                      //$$ = "int\0";
                                    }
                                    $$ = "bool\0";
                                   }
                |       exp GE exp {
                                    if(strcmp($1,"int") == 0 && 
                                      strcmp($3,"int") == 0) {
                                      //$$ = $1;
                                    }
                                    else {
                                      printf("Line %d: Illegal types in "
                                          "expression operator >= expects "
                                          "Integer\n",lineno);
                                      //$$ = "int\0";
                                    }
                                    $$ = "bool\0";
                                   }
                |       exp AND exp {if(strcmp($1,"bool") == 0 &&
                                          strcmp($3,"bool") == 0) {
                                       $$ = $1;
                                     }
                                     else {
                                       printf("Line %d: Illegal types in "
                                           "expression operator and "
                                           "expects Boolean\n",lineno);
                                       $$ = "bool\0";
                                     }
                                    }
                |       exp OR exp {if(strcmp($1,"bool") == 0 &&
                                      strcmp($3,"bool") == 0) {
                                      $$ = $1;
                                    }
                                    else {
                                      printf("Line %d: Illegal types in "
                                          "expression operator or expects "
                                          "Boolean\n",lineno);
                                      //printf("%s OR %s\n",$1,$3);
                                      $$ = "bool\0";
                                    }
                                   }
                |       NOT exp {if(strcmp($2,"bool") != 0) {
                                   printf("Line %d: Illegal type in expression "
                                       "operator ! expects Boolean\n",lineno);
                                 }
                                 $$ = "bool\0";
                                }
                |       exp PLUS exp {if(strcmp($1,"int") == 0 &&
                                        strcmp($3,"int") == 0) {
                                        $$ = $1;
                                      }
                                      else {
                                        //printf("%s PLUS %s\n",$1,$3);
                                        // check for id types, if all fails
                                        // return message
                                        printf("Line %d: Illegal "
                                            "types in expression operator + "
                                            "expects Integers\n",lineno);
                                        $$ = "int\0";
                                      }
                                     }
                |       exp MINUS exp {if(strcmp($1,"int") == 0 &&
                                         strcmp($3,"int") == 0) {
                                         $$ = $1;
                                       }
                                       else {
                                         printf("Line %d: Illegal types in "
                                             "expression operator - expects "
                                             "Integers\n",lineno);
                                         $$ = "int\0";
                                       }
                                      }
                |       exp MULT exp {if(strcmp($1,"int") == 0 &&
                                        strcmp($3,"int") == 0) {
                                        $$ = $1;
                                      }
                                      else {
                                        printf("Line %d: Illegal types in "
                                            "expression operator * "
                                            "expects Integers\n",lineno);
                                      }
                                     }
                |       MINUS exp {if(strcmp($2,"int") == 0) {
                                     $$ = $2;
                                   }
                                   else {
                                     printf("Line %d: Illegal types in "
                                         "expression operator - expects "
                                         "Integers\n",lineno);
                                   }
                                  }
                |       LP exp RP {$$ = $2;}
                |       ID LB exp RB {//printf("%s[%s]\n", $1,$3);
                                       if(lookup($1)) {
                                         Node *tmp = get($1,lookup_table);
                                         if(strcmp(tmp->info->data_type,"int")
                                             != 0 && strcmp(tmp->info->type,
                                               "Array") != 0) {
                                           printf("Line %d: Use of non-array "
                                               "type as an array: %s\n",lineno,
                                               $1);
                                         }
                                       }
                                       if(strcmp($3,"bool") == 0 || strcmp($3,
                                             "unknown") == 0) {
                                         printf("Line %d: Array indices must "
                                             "be type integer\n",lineno);
                                       }
                                       else {
                                         $$ = "int\0";
                                       }
                                     }
                |       ID LP RP {//printf("%s()\n",$1);
                                   if(lookup($1)) {
                                     Node *tmp = get($1,lookup_table);
                                     if(strcmp(tmp->info->type,"Function") !=
                                         0) {
                                       printf("Line %d: Non-function variable "
                                           "used as a function: %s\n",lineno,$1);
                                     }
                                     else {
                                       //printf("function is type %s\n",tmp->info->data_type);
                                       $$ = tmp->info->data_type;
                                     }
                                   }
                                 }
                |       ID LP param_list RP {//printf("%s()\n",$1);
                                   if(lookup($1)) {
                                     Node *tmp = get($1,lookup_table);
                                     if(strcmp(tmp->info->type,"Function")
                                         != 0) {
                                       printf("Line %d: Non-function variable "
                                         "used as a function: %s\n",lineno,$1);

                                     }
                                     else {
                                       if(strcmp(tmp->info->data_type,"na") == 0) {
                                         //printf("^^^^^^^^^^^^^^^^^^^^^^^^^^\n");
                                         //printf("^^^^^^^^^keep an eye^^^^^^\n");
                                         put(tmp->info->id_name,"int\0",
                                             tmp->info->type,tmp->info->line_no,tmp->info->args,stack->head->table);
                                         $$ = "int\0";
                                       }
                                       //printf("%s data type: %s\n",$1,tmp->info->data_type);
                                       else {
                                         $$ = tmp->info->data_type;
                                       }
                                     }
                                   }
                                   if(strcmp($3,"bool") == 0 || strcmp(
                                         $3,"unknown") == 0) {
                                     printf("Line %d: Illegal parameter type: "
                                         "Integer or array expected on function "
                                         ": %s\n",lineno,$1);
                                   }
                                   num_args = 0;
                                 }
                |       INT_LIT {$$ = "int\0";}
                |       ID {//printf("ID: %s\n",$1);
                            if(lookup($1)) {
                              Node *tmp = get($1,lookup_table);
                              if(strcmp(tmp->info->type,"Function") == 0) {
                                printf("Line %d: Illegal function usage: %s\n",
                                    lineno,$1);
                              }
                              else if(strcmp(tmp->info->type,"Variable") == 0){
                                //printf("----------------------Variable %s Type %s\n",$1,tmp->info->data_type);
                                $$ = tmp->info->data_type;
                              }
                              else if(strcmp(tmp->info->type,"Array") == 0) {
                                $$ = "Array\0";
                              }
                            }
                            else {
                              printf("Line %d: Undefined variable: %s\n",lineno,$1);
                              $$ = "unknown\0";
                            }
                           }
                |       TRUE_T{$$ = "bool\0";}
                |       FALSE_T{$$ = "bool\0";}
                ;

int_list        :       int_list COMMA INT_LIT 
                |       INT_LIT
                ;

print_stmt      :       PRINT_T exp {$$ = $1; if(strcmp($2,"bool") == 0 ||
                                                strcmp($2, "Array") == 0) {
                                                  printf("Line %d: Print "
                                                      "statement expects "
                                                      "integers\n",lineno);
                                              }
                        }
                ;

input_stmt      :       ID ASSIGN INPUT_T 
                            { 
                              if(lookup($1)) {
                                Node *tmp = get($1,lookup_table);
                                if(strcmp(tmp->info->data_type,"int") != 0) {
                                  printf("Line %d: Can only input integer "
                                    "type\n",lineno);
                                }
                              }
                              else {
                                //printf("%s ASSIGN input\n",$1);
                                put($1,"int\0","Variable\0",lineno,-1,stack->head->table);
                              }
                            }
                ;

condition_stmt  :       IF_T exp 
                        {
                          if(strcmp($2,"bool") != 0) {
                            printf("Line %d: If statement requires "
                                "boolean condition\n",lineno);
                          }
                        }
                        COLON statements optional_else FI_T 
                ;

optional_else	  :	      ELSE_T COLON statements
		            |
		            ;

while_stmt      :       WHILE_T  exp 
                          {if(strcmp($2,"int") == 0) {
                             printf("Line %d: While statement requires "
                                 "boolean condition\n",lineno);
                           }
                          }
                        COLON statements ELIHW_T 
                ;

param_list      :       param_list COMMA exp {num_args++;
                                              //printf("ARG LIST %d\n",num_args);
                                              if(strcmp($3,"unknown") == 0 ||
                                                  strcmp($1,"unknown") == 0) {
                                                $$ = "unknown\0";
                                              }
                                             }
                |       exp {if(strcmp($1,"bool") == 0) {
                               $$ = "bool\0";
                             }
                             if(strcmp($1,"unknown") == 0) {
                               $$ = "unknown\0";
                             }
                             num_args++;
                             //printf("arg_list: %d\n", num_args);
                            }
                ;

end_list        :       end_list end
                |       end
                ;

end             :       call_stmt 
                |       print_stmt
                |       ID ASSIGN INPUT_T 
                            { 
                              if(lookup($1)) {
                                Node *tmp = get($1,lookup_table);
                                if(strcmp(tmp->info->data_type,"int") != 0) {
                                  printf("Line %d: Can only input integer "
                                    "type\n",lineno);
                                }
                              }
                              else {
                                //printf("%s ASSIGN input\n",$1);
                                put($1,"int\0","Variable\0",lineno,-1,stack->head->table);
                              }
                            }
                |       ID ASSIGN exp {// printf("%s ASSIGN %s\n", $1,$3);
                                         put($1,$3,"Variable\0",lineno,-1,stack->head->table);
                                      }
                |       ID ASSIGN  
			                  LB int_list RB {
                                         put($1,"int\0","Array\0",lineno,-1,stack->head->table);
                                       }
                |       ID LB exp RB ASSIGN exp
                ; 
%%

yyerror() {
  fprintf(stderr,"Syntax error: line %d\n",lineno);
}

Scope *exitScope(char* id, char *type) {
  // update print_it global table to void
  //printf("---------------exit scope %s ---------------" 
      //"                  num_param %d\n",id,num_param);
  pop(stack);
  if(stack->head == NULL) {
    //printf("We got a problem\n");
    exit(5);
  }
  put(id,type,"Function\0",lineno,num_param,stack->head->table);
  Node *tmp = get(id,stack->head->table);
  num_param = 0;
}

Scope *enterScope(char *id) {
  // initialize a new scope
  Scope *sc = malloc(sizeof(Scope));
  if(sc == NULL) {
    fprintf(stderr,"Fatal Error Malloc Scope\n");
    exit(1);
  }
  // update the curr table
  if(stack->head != NULL) {
    put(id,"na\0","Function\0",lineno,-1,stack->head->table);
  }
  int id_len = strlen(id);
  sc->name = malloc(id_len + 1);
  memcpy(sc->name,id,id_len);
  sc->name[id_len] = '\0';
  sc->table = init_hashmap(DFLT_CAP);
  // check if stack is empty
  push(stack,sc);
  return sc;
}

int lookup(char *id) {
  // point to stack head and traverse until id found or return 0
  Scope *tmp = stack->head;
  while(tmp != NULL) {
    int bucket_idx = hash(id,tmp->table->capacity);
    LinkedList *bucket = tmp->table->table[bucket_idx];
    Node *node;
    node = seek_bucket_entry(bucket_idx,id,bucket);
    if(bucket != NULL) {
      node = seek_bucket_entry(bucket_idx,id,bucket);
      if(node != NULL) {
        lookup_table = tmp->table;
        return 1;
      }
    }
    tmp = tmp->next;

  }
  return 0;
}


int main(int argc, char **argv) {
  map = init_hashmap(DFLT_CAP);
  stack = init_stack();
  enterScope("global\0");
  // enter into global scope, point map to global map
  yyparse();
  return 0;
}
