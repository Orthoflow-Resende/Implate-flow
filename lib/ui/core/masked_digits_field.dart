import 'package:flutter/material.dart';

import '../../domain/models.dart';

class MaskedDigitsField extends StatefulWidget {
  const MaskedDigitsField({
    super.key,
    required this.initial,
    required this.label,
    required this.format,
    required this.issue,
    required this.onChanged,
    this.helperText,
    this.keyboardType = TextInputType.number,
  });

  final String initial;
  final String label;
  final String? helperText;
  final TextInputType keyboardType;
  final String Function(String value) format;
  final String? Function(String value) issue;
  final ValueChanged<String> onChanged;

  @override
  State<MaskedDigitsField> createState() => _MaskedDigitsFieldState();
}

class _MaskedDigitsFieldState extends State<MaskedDigitsField> {
  late final TextEditingController controller;
  late String previous;
  var applying = false;

  @override
  void initState() {
    super.initState();
    previous = widget.format(widget.initial);
    controller = TextEditingController(text: previous);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _apply(String incoming) {
    if (applying) return;
    final masked = applyDigitMask(
      previous: previous,
      incoming: incoming,
      cursor: controller.selection.extentOffset,
      format: widget.format,
    );
    previous = masked.text;
    applying = true;
    controller.value = TextEditingValue(
      text: masked.text,
      selection: TextSelection.collapsed(offset: masked.offset.clamp(0, masked.text.length)),
    );
    applying = false;
    widget.onChanged(masked.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        errorText: widget.issue(controller.text),
      ),
      onChanged: _apply,
    );
  }
}
