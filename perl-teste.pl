#!/usr/bin/perl
# Teste do compilador PERL

use strict;
use warnings;

# Declaração e inicialização de variáveis
my $a;
my $b = 10;

# Teste de print
print "Hello World\n";

# Teste de variável
my $x = 10;

# Teste de if
if ($x > 5) {
    print "x é maior que 5\n";
}

# Teste de if-else
if ($x < 20) {
    print "x é menor que 20\n";
} else {
    print "x é maior ou igual a 20\n";
}

# Teste de for
for (my $i = 0; $i < 5; $i++) {
    print "Iteração do loop\n";
}



# Testes de erro (comentados)
# Teste de variável não inicializada
# print $a;  # Deve gerar erro semântico

# Teste de variável não declarada
# $c = 30;  # Deve gerar erro semântico

# Teste de tipo incompatível
# my $y;
# $y = 3.14;  # Deve gerar erro de tipo 