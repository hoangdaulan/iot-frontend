import 'package:flutter/material.dart';
import 'package:gp1/presentation/widgets/app_text_field.dart';
import 'package:gp1/presentation/widgets/table/app_table_column_filter.dart';
import 'package:gp1/presentation/widgets/table/table_filter_action.dart';

class TableSearchFilter extends AppTableColumnFilter {
  final String? labelText;
  final String? initialValue;
  final Function(String?)? onChanged;

  const TableSearchFilter({this.labelText, this.initialValue, this.onChanged});

  @override
  bool get isActive => initialValue?.isNotEmpty == true;

  @override
  Widget overlay(BuildContext context, VoidCallback hideOverlay) {
    return _TableSearchFilterContent(
      hideOverlay: hideOverlay,
      labelText: labelText,
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}

class _TableSearchFilterContent extends StatefulWidget {
  const _TableSearchFilterContent({
    required this.hideOverlay,
    this.labelText,
    this.initialValue,
    this.onChanged,
  });

  final VoidCallback hideOverlay;
  final String? labelText;
  final String? initialValue;
  final Function(String?)? onChanged;

  @override
  State<_TableSearchFilterContent> createState() => __TableSearchFilterContentState();
}

class __TableSearchFilterContentState extends State<_TableSearchFilterContent> {
  late String? value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  bool get isActive => widget.initialValue?.isNotEmpty == true;
  bool get isChanged => value != widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          style: .noBorder,
          decoration: InputDecoration(labelText: widget.labelText),
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
        const Divider(height: 1),
        TableFilterAction(
          onClear: isActive
              ? () {
                  widget.onChanged?.call(null);
                  widget.hideOverlay();
                }
              : null,
          onCancel: widget.hideOverlay,
          onApply: isChanged
              ? () {
                  widget.onChanged?.call(value);
                  widget.hideOverlay();
                }
              : null,
        ),
      ],
    );
  }
}
