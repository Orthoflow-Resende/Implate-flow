import 'package:flutter/material.dart';

import '../../domain/models.dart';

class BrazilianPhoneField extends StatefulWidget {
  const BrazilianPhoneField({super.key, required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<BrazilianPhoneField> createState() => _BrazilianPhoneFieldState();
}

class _BrazilianPhoneFieldState extends State<BrazilianPhoneField> {
  late final TextEditingController controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Telefone',
        errorText: brazilianPhoneIssue(controller.text),
      ),
      onChanged: (value) {
        final formatted = formatBrazilianPhone(value);
        if (formatted != value) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
        widget.onChanged(formatted);
        setState(() {});
      },
    );
  }
}
