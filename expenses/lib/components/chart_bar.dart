import 'package:flutter/material.dart'; // Importa a biblioteca Material do Flutter para criação da interface.

class ChartBar extends StatelessWidget {
  final String label; // Rótulo da barra, que indica o dia da semana.
  final double value; // Valor total das transações daquele dia.
  final double
  percentage; // Porcentagem que a barra ocupa em relação ao valor total da semana.

  // Construtor que recebe os valores necessários para criar a barra.
  const ChartBar({
    required this.label, // Rótulo (dia da semana).
    required this.value, // Valor total das transações daquele dia.
    required this.percentage, // Porcentagem para determinar o tamanho da barra.
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Método build para renderizar o widget.
    return Column(
      // Exibe os elementos de forma vertical (em coluna).
      children: [
        //Exibe a porcentagem no topo, mas oculta se for 0
        const SizedBox(height: 0),
        // Exibe o valor formatado como moeda (exemplo: R$100.00).
        SizedBox(
          height: 25, // Define a altura do container do valor.
          child: FittedBox(
            // O FittedBox ajusta o texto para caber no espaço disponível.
            child: Text(
              '${value.toStringAsFixed(2)}', // Formata o valor para exibir com 2 casas decimais.
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 1), // Adiciona um espaço de 5 pixels.
        // Barra de gráfico ajustada de acordo com a porcentagem.
        SizedBox(
          height: 80, // Define a altura da barra do gráfico.
          width: 20, // Define a largura da barra do gráfico.
          child: Stack(
            // Stack permite sobrepor widgets.
            alignment:
                Alignment
                    .bottomCenter, // Alinha os filhos da Stack na parte inferior.
            children: <Widget>[
              // Fundo da barra, com borda e cor de fundo.
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey, // Cor da borda da barra.
                    width: 1.0, // Largura da borda.
                  ),
                  color: const Color.fromRGBO(
                    220,
                    220,
                    220,
                    1,
                  ), // Cor de fundo da barra (cinza claro).
                  borderRadius: BorderRadius.circular(
                    5,
                  ), // Bordas arredondadas.
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
                ),
              ),
              // Barra Coloriad animaa proporcional ao valor
              AnimatedContainer(
                duration: const Duration(microseconds: 500),
                height: 80 * percentage, // Altura baseada na porcentagem
                decoration: BoxDecoration(
                  color:
                      percentage > 0.7
                          ? Colors
                              .red // Alta porcentagem => vermelho
                          : percentage > 0.4
                          ? Colors
                              .orange // méia porcentagem => laranja
                          : Colors.green, // Baixa porcentagem => verde
                  borderRadius: BorderRadius.circular(5),
                ),
              ),

              // A parte da barra que representa o valor proporcional.
              FractionallySizedBox(
                heightFactor:
                    percentage, // A altura da barra é proporcional à porcentagem.
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple], // Cor da barra
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),

                    borderRadius: BorderRadius.circular(
                      5,
                    ), // Bordas arredondadas para a barra.
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 1), // Adiciona um espaço de 5 pixels.
        // Exibe o rótulo, que é o dia da semana (ou qualquer outro texto para a barra).
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold, // Negrito para melhor leitura
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 10),

        if (percentage > 0)
          Text(
            '${(percentage * 100).toStringAsFixed(2)}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
