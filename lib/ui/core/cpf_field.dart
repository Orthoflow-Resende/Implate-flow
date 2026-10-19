import 'package:flutter/material.dart';

import '../../domain/models.dart';
import 'masked_digits_field.dart';

class CpfField extends StatelessWidget {
  const CpfField({super.key, required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return MaskedDigitsField(
      initial: initial,
      label: 'CPF',
      helperText: 'Usado na busca da lista',
      format: formatCpf,
      issue: cpfIssue,
      onChanged: onChanged,
    );
  }
}
