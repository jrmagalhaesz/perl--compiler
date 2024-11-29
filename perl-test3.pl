# Teste com múltiplas verificações
my $valor1;
my $valor2 = 10;
my $valor1 = 20;    # Erro: declaração duplicada

$nao_declarada = 30;  # Erro: variável não declarada

print $valor1;      # Aviso: uso de variável não inicializada
print $valor2 + "abc";  # Erro: tipos incompatíveis