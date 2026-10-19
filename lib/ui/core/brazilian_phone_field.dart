import 'package:flutter/material.dart';

import '../../domain/models.dart';
import 'masked_digits_field.dart';

class BrazilianPhoneField extends StatelessWidget {
  const BrazilianPhoneField({super.key, required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return MaskedDigitsField(
      initial: initial,
      label: 'Telefone',
      keyboardType: TextInputType.phone,
      format: formatBrazilianPhone,
      issue: brazilianPhoneIssue,
      onChanged: onChanged,
    );
  }
}
