import 'package:flutter/material.dart'; // Importa a biblioteca Material do Flutter, que contém widgets e temas para criar interfaces.
import 'package:intl/intl.dart'; // Importa a biblioteca intl para formatação de datas.
import 'adaptative_button.dart';
import 'adaptative_text_field.dart';
import 'adaptative_date_picker.dart';

class TransactionForm extends StatefulWidget {
  final void Function(String, double, DateTime)
  onSubmit; // Declara um callback para o envio do formulário (recebe título, valor e data).

  TransactionForm(this.onSubmit, {Key? key})
    : super(key: key); // Construtor que inicializa o callback onSubmit.

  @override
  State<TransactionForm> createState() => _TransactionFormState(); // Cria o estado do formulário (TransactionFormState).
}

class _TransactionFormState extends State<TransactionForm> {
  final _titleController =
      TextEditingController(); // Controlador para o campo de texto do título.
  final _valueController =
      TextEditingController(); // Controlador para o campo de texto do valor.
  DateTime? _selectedDate =
      DateTime.now(); // Variável para armazenar a data selecionada (inicialmente a data atual).

  _submitForm() {
    // Função que será chamada quando o formulário for enviado.
    final title =
        _titleController.text; // Obtém o título inserido no campo de texto.
    final value =
        double.tryParse(_valueController.text) ??
        0.0; // Tenta converter o valor inserido em double; se falhar, atribui 0.0.

    if (title.isEmpty || value <= 0 || _selectedDate == null) {
      // Verifica se os dados são válidos.
      return; // Se algum dado estiver inválido, retorna sem fazer nada.
    }

    widget.onSubmit(
      title,
      value,
      _selectedDate!,
    ); // Chama o callback onSubmit com os dados válidos.
  }

  @override
  Widget build(BuildContext context) {
    // Método build que retorna a interface do formulário.
    return SingleChildScrollView(
      child: Card(
        // Cria um card para conter o formulário.
        elevation: 5, // Define a elevação do card, criando um efeito de sombra.
        child: Padding(
          // Adiciona um preenchimento interno ao card.
          padding: EdgeInsets.only(
            top: 10,
            left: 10,
            right: 10,
            bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
          ), // Define o espaço interno de 10 pixels ao redor do conteúdo.
          child: Column(
            // Cria uma coluna para empilhar os widgets.
            children: <Widget>[
              AdaptativeTextField(
                // Campo de texto para o título da transação.
                controller:
                    _titleController, // Controlador para pegar o valor do campo.
                onSubmitted:
                    (_) =>
                        _submitForm(), // Chama a função _submitForm ao pressionar enter.
                label: 'Título', // Define o texto do rótulo do campo.
              ),

              AdaptativeTextField(
                // Campo de texto para o valor da transação.
                controller:
                    _valueController, // Controlador para pegar o valor do campo.
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ), // Define o tipo de teclado para valores numéricos.
                onSubmitted:
                    (_) =>
                        _submitForm(), // Chama a função _submitForm ao pressionar enter.

                label:
                    'Valor (R\$)', // Define o texto do rótulo para o campo de valor.
              ),
              // Novo Componente
              AdaptativeDatePicker(
                selectedDate: _selectedDate!,
                onDateChange: (newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
              ),
              Row(
                // Cria uma linha para o botão de envio do formulário.
                mainAxisAlignment:
                    MainAxisAlignment.end, // Alinha o botão à direita.
                children: <Widget>[
                  AdaptativeButton(
                    label: 'Nova Transação',
                    onPressed: _submitForm,
                  ),
                  // ElevatedButton(
                  //   // Botão para enviar a transação.
                  //   child: const Text(
                  //     'Nova Transação', // Texto do botão.
                  //     style: TextStyle(
                  //       color: Colors.white, // Cor do texto.
                  //       fontWeight: FontWeight.bold, // Estilo do texto.
                  //     ),
                  //   ),
                  //   onPressed:
                  //       _submitForm, // Chama a função _submitForm ao pressionar o botão.
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
