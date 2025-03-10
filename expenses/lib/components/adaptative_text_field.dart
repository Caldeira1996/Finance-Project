import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';

class AdaptativeTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final Function(String)? onSubmitted;

  const AdaptativeTextField({
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.onSubmitted,
    required this.label,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? Padding(
          padding: const EdgeInsets.only(bottom: 10),

          child: CupertinoTextField(
            controller: controller,
            keyboardType: keyboardType,
            onSubmitted: onSubmitted,
            placeholder: label,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          ),
        )
        : TextField(
          controller: controller,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(labelText: label),
        );
  }
}
