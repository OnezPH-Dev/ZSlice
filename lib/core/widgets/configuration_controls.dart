import 'package:flutter/material.dart';
import 'app_icons.dart';

class InspectorSection extends StatelessWidget {
  const InspectorSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });
  final String title;
  final Widget icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: PageStorageKey(title),
    initiallyExpanded: initiallyExpanded,
    shape: Border(
      bottom: BorderSide(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    collapsedShape: Border(
      bottom: BorderSide(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    leading: icon,
    title: Text(title, style: Theme.of(context).textTheme.titleSmall),
    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    childrenPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ],
  );
}

class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label, value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey('$label$value'),
    initialValue: value,
    isExpanded: true,
    icon: AppIcons.arrowDown,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onCommit,
    this.integer = false,
    this.min,
    this.max,
  });
  final String label;
  final double value;
  final ValueChanged<double> onCommit;
  final bool integer;
  final double? min, max;
  @override
  State<NumberField> createState() => _NumberFieldState();
}

class HexColorField extends StatefulWidget {
  const HexColorField({
    super.key,
    required this.label,
    required this.value,
    required this.onCommit,
  });
  final String label;
  final int value;
  final ValueChanged<int> onCommit;
  @override
  State<HexColorField> createState() => _HexColorFieldState();
}

class _HexColorFieldState extends State<HexColorField> {
  late final controller = TextEditingController(text: hex(widget.value));
  final scroll = ScrollController(keepScrollOffset: false);
  String? error;
  String hex(int color) =>
      (color & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase();
  @override
  void didUpdateWidget(HexColorField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) controller.text = hex(widget.value);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    scrollController: scroll,
    decoration: InputDecoration(labelText: widget.label, errorText: error),
    onChanged: (text) {
      final cleaned = text.replaceFirst('#', '').trim();
      if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) {
        setState(() => error = null);
        widget.onCommit(0xff000000 | int.parse(cleaned, radix: 16));
      }
    },
    onSubmitted: (text) {
      final cleaned = text.replaceFirst('#', '').trim();
      if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) {
        setState(() => error = 'Use six hexadecimal digits');
        return;
      }
      setState(() => error = null);
      widget.onCommit(0xff000000 | int.parse(cleaned, radix: 16));
    },
  );
  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController controller;
  // ExpansionTile stores a bool under its PageStorageKey. An input's internal
  // scroll view must not read/write that same key as a scroll offset.
  final scroll = ScrollController(keepScrollOffset: false);
  final focus = FocusNode();
  String? error;
  double? pendingValue;
  String display(double v) => widget.integer
      ? v.toInt().toString()
      : v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: display(widget.value));
    focus.addListener(() {
      if (!focus.hasFocus && mounted) {
        if (error == null) controller.text = display(widget.value);
      }
    });
  }

  @override
  void didUpdateWidget(NumberField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final ownEdit =
          pendingValue != null && (widget.value - pendingValue!).abs() < 1e-9;
      pendingValue = null;
      // Keep the caret while typing, but always reflect undo, presets and
      // other external changes, even when this field still has focus.
      if (!focus.hasFocus || !ownEdit) {
        controller.text = display(widget.value);
        error = null;
      }
    }
  }

  void commit(String text) {
    final v = double.tryParse(text);
    String? message;
    if (v == null ||
        !v.isFinite ||
        (widget.integer && v != v.roundToDouble())) {
      message = 'Enter a valid number';
    } else if (widget.min != null && v < widget.min! ||
        widget.max != null && v > widget.max!) {
      message = 'Outside allowed range';
    } else {
      try {
        pendingValue = v;
        widget.onCommit(v);
      } on FormatException catch (e) {
        pendingValue = null;
        message = e.message;
      }
    }
    setState(() => error = message);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    scrollController: scroll,
    focusNode: focus,
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    decoration: InputDecoration(
      labelText: widget.label,
      errorText: error,
      errorMaxLines: 3,
    ),
    textInputAction: TextInputAction.done,
    onChanged: commit,
    onSubmitted: commit,
    onTapOutside: (_) => focus.unfocus(),
  );
  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    focus.dispose();
    super.dispose();
  }
}
