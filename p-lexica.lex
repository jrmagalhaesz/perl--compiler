%{
#include <string.h>
#include <stdio.h>
#include "p-sin-sem-cod-interm.tab.h" 

FILE *out = NULL;
int linha;

void init_lexer() {
    out = fopen("tokens.txt", "w");
    if (!out) {
        fprintf(stderr, "Erro ao criar arquivo de tokens\n");
        exit(1);
    }
    fprintf(out, "\t\tLista de Tokens Reconhecidos\n");
    fprintf(out, "+-----------------+-----------------+----------+\n");
    fprintf(out, "| Linha          | Token           | Lexema   |\n");
    fprintf(out, "+-----------------+-----------------+----------+\n");
}

void close_lexer() {
    if (out) {
        fprintf(out, "+-----------------+-----------------+----------+\n");
        fclose(out);
        out = NULL;
    }
}

void print_token(const char* token, const char* lexema) {
    if (!out) {
        init_lexer();
    }
    fprintf(out, "| %-15d | %-15s | %-8s |\n", yylineno, token, lexema);
}

%}

%option noinput
%option nounput
%option yylineno
%x COMMENT
%x POD_COMMENT

/* Definições de padrões */
digit       [0-9]
letter      [a-zA-Z]
ID          [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE  [ \t]
quebra      \n
STRING      \"[^\"]*\"
SCALAR      \$[a-zA-Z_][a-zA-Z0-9_]*
COMMENT     #[^\n]*

%%

{COMMENT}\n    { /* Ignora comentários de linha incluindo a quebra de linha */ }
{COMMENT}      { /* Ignora comentários de linha sem quebra de linha */ }
"=pod"         { BEGIN(POD_COMMENT); }
<POD_COMMENT>"=cut"     { BEGIN(INITIAL); }
<POD_COMMENT>.|\n       ; /* Ignora conteúdo do POD */

"if"        { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("IF", yytext); return IF; }
"else"      { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("ELSE", yytext); return ELSE; }
"for"       { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("FOR", yytext); return FOR; }
"++"        { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("INC", yytext); return INC; }
"my"        { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("MY", yytext); return MY; }
"use"       { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("USE", yytext); return USE; }
"print"     { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("PRINT", yytext); return PRINT; }

"<"         { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("LT", yytext); return LT; }
">"         { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("GT", yytext); return GT; }
"<="        { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("LE", yytext); return LE; }
">="        { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("GE", yytext); return GE; }
"=="        { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("EQ", yytext); return EQ; }
"!="        { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("NE", yytext); return NE; }

{SCALAR}    { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("SCALAR", yytext); yylval.str = strdup(yytext); return SCALAR; }
{STRING}    { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("STRING", yytext); yylval.str = strdup(yytext); return STRING; }
{digit}+    { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("NUMBER_INT", yytext); yylval.num = atoi(yytext); return NUMBER_INT; }
{digit}+\.{digit}+ { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("NUMBER_FLOAT", yytext); yylval.num = atoi(yytext); return NUMBER_FLOAT; }

[+\-*/=;(),{}]  { 
    char token[2] = {yytext[0], '\0'};
    print_token("OPERATOR", token); 
    printf("(Análise Léxica): reconhecido token %s\n", token);
    return yytext[0]; 
}

{WHITESPACE}+|{quebra}  ; /* Ignora espaços em branco */
{ID}        { printf("(Análise Léxica): reconhecido token %s\n", yytext); print_token("IDENTIFIER", yytext); yylval.str = strdup(yytext); return IDENTIFIER; }

.           { printf("Reconhecido token de erro: %s\n", yytext); print_token("ERROR", yytext); return ERROR; }

%%

int yywrap() {
    close_lexer();
    return 1;
} 