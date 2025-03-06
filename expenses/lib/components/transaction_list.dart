import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

// Widget que exibe a lista de transações
class TransactionList extends StatelessWidget {
  final List<Transaction> transactions; // Lista de transações recebida
  final void Function(String) onRemove; // Função para remover uma transação

  // Construtor da classe TransactionList
  const TransactionList(this.transactions, this.onRemove, {Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return transactions
            .isEmpty // Verifica se a lista está vazia
        ? LayoutBuilder(
          builder: (ctx, constraints) {
            return Column(
              children: [
                SizedBox(
                  height: 20,
                  // MediaQuery.of(context).size.height * 0.3 > 200
                  //     ? 200
                  //     : MediaQuery.of(context).size.height * 0.3,
                ), // Espaçamento
                Text(
                  'Nenhuma Transação Cadastrada!', // Mensagem de aviso
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20), // Espaçamento
                SizedBox(
                  height: constraints.maxHeight * 0.6, // Altura da imagem
                  child: Image.asset(
                    'assets/images/waiting.png', // Imagem padrão quando não há transações
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            );
          },
        )
        : ListView.builder(
          itemCount: transactions.length, // Número de itens na lista
          itemBuilder: (ctx, index) {
            final tr = transactions[index]; // Obtém a transação atual
            return Card(
              elevation: 5, // Sombra no card
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple, // Cor de fundo do avatar
                  radius: 30, // Define o tamanho do círculo
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: FittedBox(
                      child: Text(
                        'R\$${tr.value}', // Exibe o valor da transação
                        style: const TextStyle(
                          color: Colors.white, // Cor do texto
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  tr.title, // Exibe o título da transação
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                subtitle: Text(
                  DateFormat(
                    'd MMM y',
                  ).format(tr.date), // Exibe a data formatada
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                trailing:
                    MediaQuery.of(context).size.width > 400
                        ? TextButton.icon(
                          onPressed: () => onRemove(tr.id),
                          icon: Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          label: Text(
                            'Excluir',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                            minimumSize: Size(
                              80,
                              40,
                            ), // Define um tamanho minumo do botão
                          ),
                        )
                        : IconButton(
                          icon: Icon(Icons.delete), // Ícone de lixeira
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.error, // Cor do ícone
                          onPressed:
                              () => onRemove(
                                tr.id,
                              ), // Chama a função para remover a transação
                        ),
              ),
            );
          },
        );
  }
}
