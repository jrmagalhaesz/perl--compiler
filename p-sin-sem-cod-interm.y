%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(), nId = 0;
void addSymbol(char *name, char *type, int line); 
void generateIntermediateCode(const char *code);
void checkVariableDeclared(char *name);
void checkVariableType(char *name, char *expectedType);
void semanticError(const char *message, int line);
void updateSymbolInitialization(char *name);

int labelCount = 0;  // Contador para labels únicos

extern int yylineno;
extern FILE *yyin;

typedef struct {
    char *name;
    char *type;
    int line;
    int initialized;
    int size;          
    char *scope;       
    char *category;    
} Symbol;

#define MAX_SYMBOLS 100

Symbol symbolTable[MAX_SYMBOLS];
int symbolCount = 0;

char intermediateCode[1000][100];
int intermediateLine = 0;

extern void init_lexer();
extern void close_lexer();

FILE *intermediate_out = NULL;

void init_intermediate_code() {
    intermediate_out = fopen("codigo-intermediario.txt", "w");
    if (!intermediate_out) {
        fprintf(stderr, "Erro ao criar arquivo de código intermediário\n");
        exit(1);
    }
    fprintf(intermediate_out, "\t\tCódigo Intermediário Gerado\n");
    fprintf(intermediate_out, "+--------------------------------+\n");
}

void close_intermediate_code() {
    if (intermediate_out) {
        fprintf(intermediate_out, "+--------------------------------+\n");
        fclose(intermediate_out);
        intermediate_out = NULL;
    }
}

%}

%union {
    int num;
    char *str;
    struct {
        char *type;
        int value;
        float fvalue;
    } expr;
}

%token <num> NUMBER_INT NUMBER_FLOAT
%token MY USE PRINT IF ELSE FOR
%token <str> IDENTIFIER STRING SCALAR
%token INC LT GT LE GE EQ NE
%token ERROR

%type <expr> expr condition for_init for_update
%type <str> comparison_op

%left LT GT LE GE EQ NE
%left '+' '-'
%left '*' '/'

%%

program:
    use_stmts statements
    ;

use_stmts:
    use_stmts use_stmt
    | /* vazio */
    ;

use_stmt:
    USE IDENTIFIER ';' { printf("(Análise Sintática/Semântica): reconhecido: use %s\n", $2); }
    ;

statements:
    statements statement
    | /* vazio */
    ;

statement:
    scalar_decl
    | scalar_assign
    | print_stmt
    | if_stmt
    | if_else_stmt
    | for_stmt
    ;

scalar_decl:
    MY SCALAR ';' 
    { 
        addSymbol($2, "scalar", nId); 
        printf("(Análise Sintática/Semântica): reconhecido: declaração %s\n", $2);
    }
    | MY SCALAR '=' expr ';'
    {
        addSymbol($2, "scalar", nId);
        updateSymbolInitialization($2);
        printf("(Análise Sintática/Semântica): reconhecido: declaração com inicialização %s\n", $2);
        char code[100];
        sprintf(code, "%s = %d", $2, $4.value);
        generateIntermediateCode(code);
    }
    ;

scalar_assign:
    SCALAR '=' expr ';'
    {
        checkVariableDeclared($1);
        updateSymbolInitialization($1);
        printf("(Análise Sintática/Semântica): reconhecido: atribuição %s\n", $1);
        char code[100];
        sprintf(code, "%s = %d", $1, $3.value);
        generateIntermediateCode(code);
    }
    ;

print_stmt:
    PRINT expr ';'
    {
        printf("(Análise Sintática/Semântica): reconhecido: print\n");
        char code[100];
        sprintf(code, "PRINT %d", $2.value);
        generateIntermediateCode(code);
    }
    | PRINT STRING ';'
    {
        printf("(Análise Sintática/Semântica): reconhecido: print string\n");
        char code[100];
        sprintf(code, "PRINT %s", $2);
        generateIntermediateCode(code);
    }
    ;

if_stmt:
    IF '(' condition ')' '{' statements '}'
    {
        generateIntermediateCode("if_start:");
        generateIntermediateCode($3.type);
        generateIntermediateCode("jump_if_false end_if");
        generateIntermediateCode("end_if:");
    }
    ;

if_else_stmt:
    IF '(' condition ')' '{' statements '}' ELSE '{' statements '}'
    {
        generateIntermediateCode("if_start:");
        generateIntermediateCode($3.type);
        generateIntermediateCode("jump_if_false else");
        generateIntermediateCode("else:");
        generateIntermediateCode("end_if:");
    }
    ;

for_stmt:
    FOR '(' for_init condition ';' for_update ')' '{' statements '}'
    {
        generateIntermediateCode("for_start:");
        generateIntermediateCode("check_condition");
        generateIntermediateCode("jump_if_false end_for");
        generateIntermediateCode("update");
        generateIntermediateCode("jump for_start");
        generateIntermediateCode("end_for:");
    }
    ;

for_init:
    MY SCALAR '=' expr ';'
    {
        addSymbol($2, "scalar", nId);
        updateSymbolInitialization($2);
        char code[100];
        sprintf(code, "init %s = %d", $2, $4.value);
        generateIntermediateCode(code);
        $$ = $4;
    }
    ;

for_update:
    SCALAR INC
    {
        checkVariableDeclared($1);
        char code[100];
        sprintf(code, "increment %s", $1);
        generateIntermediateCode(code);
        $$.type = "scalar";
    }
    ;

condition:
    expr comparison_op expr
    {
        char code[100];
        sprintf(code, "compare %d %s %d", $1.value, $2, $3.value);
        generateIntermediateCode(code);
    }
    ;

comparison_op:
    LT { $$ = "<"; }
    | GT { $$ = ">"; }
    | LE { $$ = "<="; }
    | GE { $$ = ">="; }
    | EQ { $$ = "=="; }
    | NE { $$ = "!="; }
    ;

expr:
    NUMBER_INT
    {
        $$.type = "int";
        $$.value = $1;
    }
    | NUMBER_FLOAT
    {
        $$.type = "float";
        $$.fvalue = $1;
    }
    | SCALAR
    {
        checkVariableDeclared($1);
        $$.type = "scalar";
    }
    | expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | '(' expr ')'
    {
        $$ = $2;
    }
    ;

%%

/* Função para adicionar símbolos à tabela */
void addSymbol(char *name, char *type, int line) {
    FILE *a = fopen("tsimbolo.txt", "w");

    if (symbolCount < MAX_SYMBOLS) {
        symbolTable[symbolCount].name = strdup(name);
        symbolTable[symbolCount].type = strdup(type);
        symbolTable[symbolCount].line = line;
        symbolTable[symbolCount].initialized = 0;
        
        // Define o tamanho baseado no tipo
        if (strcmp(type, "scalar") == 0) {
            symbolTable[symbolCount].size = 8;  // 8 bytes para scalar
        } else {
            symbolTable[symbolCount].size = 0;  // 0 para outros tipos
        }
        
        // Define a categoria e escopo
        symbolTable[symbolCount].category = "variável";
        symbolTable[symbolCount].scope = "local";

        // Escreve no arquivo com o novo formato
        if (a) {
            fprintf(a, "+-----------------+-----------+--------+-------------+--------+----------+------------+\n");
            fprintf(a, "| Nome            | Tipo      | Linha  | Inicializado| Tamanho| Escopo   | Categoria  |\n");
            fprintf(a, "+-----------------+-----------+--------+-------------+--------+----------+------------+\n");
            
            for (int i = 0; i <= symbolCount; i++) {
                fprintf(a, "| %-15s | %-9s | %-6d | %-11s | %-6d | %-8s | %-10s |\n",
                    symbolTable[i].name,
                    symbolTable[i].type,
                    symbolTable[i].line,
                    symbolTable[i].initialized ? "Sim" : "Não",
                    symbolTable[i].size,
                    symbolTable[i].scope,
                    symbolTable[i].category
                );
            }
            
            fprintf(a, "+-----------------+-----------+--------+-------------+--------+----------+------------+\n");
            fclose(a);
        }

        symbolCount++;
        nId++;
    } else {
        fprintf(stderr, "Erro: tabela de símbolos cheia\n");
    }
}

/* Função para gerar código intermediário */
void generateIntermediateCode(const char *code) {
    if (intermediateLine < 1000) {
        strcpy(intermediateCode[intermediateLine++], code);
        if (intermediate_out) {
            fprintf(intermediate_out, "| %-30s |\n", code);
        }
        printf("(Código intermediário): %s\n", code);
    } else {
        fprintf(stderr, "Erro: buffer de código intermediário cheio\n");
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Erro de sintaxe na linha %d: %s\n", yylineno, s);
}

void checkVariableDeclared(char *name) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            return;
        }
    }
    char error[100];
    sprintf(error, "Variável '%s' não foi declarada", name);
    semanticError(error, yylineno);
}

void checkVariableType(char *name, char *expectedType) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            if (strcmp(symbolTable[i].type, expectedType) != 0) {
                char error[100];
                sprintf(error, "Tipo incompatível para variável '%s'", name);
                semanticError(error, yylineno);
            }
            return;
        }
    }
}

void semanticError(const char *message, int line) {
    fprintf(stderr, "Erro semântico na linha %d: %s\n", line, message);
    exit(1);
}

void updateSymbolInitialization(char *name) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            symbolTable[i].initialized = 1;
            addSymbol("", "", 0);  // Força reescrita da tabela
            break;
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <arquivo de entrada>\n", argv[0]);
        return 1;
    }
    
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Erro ao abrir o arquivo %s\n", argv[1]);
        return 1;
    }

    init_lexer();
    init_intermediate_code();
    
    int result = yyparse();

    close_lexer();
    close_intermediate_code();
    fclose(yyin);
    
    return result;
} 