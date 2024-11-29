#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Iniciando compilação do compilador PERL...${NC}"

# Cria diretório output se não existir
mkdir -p output

# Limpa arquivos anteriores
echo "Limpando arquivos anteriores..."
rm -f output/lex.yy.c output/p-sin-sem-cod-interm.tab.c output/p-sin-sem-cod-interm.tab.h output/compilador output/tsimbolo.txt output/tokens.txt output/codigo-intermediario.txt

# Gera o analisador léxico
echo "Gerando analisador léxico..."
flex -o output/lex.yy.c p-lexica.lex
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao gerar analisador léxico${NC}"
    exit 1
fi

# Gera o analisador sintático
echo "Gerando analisador sintático..."
bison -d p-sin-sem-cod-interm.y -b output/p-sin-sem-cod-interm
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao gerar analisador sintático/semântico/código intermediário${NC}"
    exit 1
fi

# Compila o programa
echo "Compilando..."
gcc -g output/lex.yy.c output/p-sin-sem-cod-interm.tab.c -o output/compilador -Wall
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro na compilação${NC}"
    exit 1
fi

# Executa o compilador com o arquivo de teste
echo -e "${GREEN}Compilação concluída! Executando testes...${NC}"
cd output
if [ ! -f "../perl-teste.pl" ]; then
    echo -e "${RED}Erro: Arquivo de teste '../perl-teste.pl' não encontrado${NC}"
    exit 1
fi

echo -e "\n${GREEN}Fluxo de Análises:${NC}"
./compilador ../perl-teste.pl
RESULT=$?
cd ..

if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}Teste concluído com sucesso!${NC}"
else
    echo -e "${RED}Erro durante a execução do teste (código de saída: $RESULT)${NC}"
    exit 1
fi

# Lista os arquivos gerados
echo -e "\nArquivos gerados em output/:"
ls -l output/compilador output/tsimbolo.txt output/tokens.txt output/codigo-intermediario.txt 2>/dev/null 