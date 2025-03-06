import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdaptativeDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChange;

  const AdaptativeDatePicker({
    required this.selectedDate,
    required this.onDateChange,
    Key? Key,
  }) : super(key: Key);

  _showDatePicker(BuildContext context) {
    // Função para exibir o seletor de data.
    showDatePicker(
      context: context,
      initialDate:
          DateTime.now(), // A data inicial no seletor será a data atual.
      firstDate: DateTime(2019), // A primeira data que pode ser selecionada.
      lastDate: DateTime.now(), // A última data que pode ser selecionada.
    ).then((pickedDate) {
      // Quando uma data for selecionada...
      if (pickedDate == null) {
        // Se nenhuma data for selecionada...
        return; // Retorna sem fazer nada.
      }

      onDateChange(pickedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? Container(
          height: 180,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: DateTime.now(),
            minimumDate: DateTime(2019),
            maximumDate: DateTime.now(),
            onDateTimeChanged: onDateChange,
          ),
        )
        : SizedBox(
          // Cria um espaço de 70 pixels de altura para exibir a data selecionada.
          height: 70,
          child: Row(
            // Cria uma linha para exibir a data e o botão de selecionar data.
            children: <Widget>[
              Expanded(
                child: Text(
                  selectedDate == null
                      ? 'Nenhuma data selecionada!' // Exibe uma mensagem se nenhuma data for selecionada.
                      : 'Data Selecionada: ${DateFormat('dd/MM/y').format(selectedDate!)}', // Exibe a data formatada.
                ),
              ),
              TextButton(
                // Botão para abrir o seletor de data.
                child: const Text(
                  'Selecionar Data', // Texto do botão.
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // Estilo do texto do botão.
                  ),
                ),
                onPressed:
                    () => _showDatePicker(
                      context,
                    ), // Chama a função para exibir o seletor de data.
              ),
            ],
          ),
        );
  }
}
