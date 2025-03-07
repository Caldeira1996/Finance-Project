import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class AdaptativeButton extends StatelessWidget {
  //const AdaptativeButton({super.key});

  final String label;
  final Function() onPressed;

  const AdaptativeButton({
    required this.label,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoButton(
          child: Text(label),
          onPressed: onPressed,
          color: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        )
        : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            'Adicionar Transação',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          onPressed: onPressed,
        );
  }
}
