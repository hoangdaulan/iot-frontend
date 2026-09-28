import 'package:flutter/material.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/models/app_field_style.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class AppDateTimePicker extends StatefulWidget {
  const AppDateTimePicker({
    super.key,
    this.style = AppFieldStyle.normal,
    this.selected,
    this.labelText,
    this.hintText = 'Chọn thời gian',
    this.formatPattern = 'dd/MM/yyyy HH:mm',
    this.onChanged,
    this.validator,
  });

  final AppFieldStyle style;
  final DateTime? selected;
  final String? labelText;
  final String hintText;
  final String formatPattern;
  final ValueChanged<DateTime?>? onChanged;
  final FormFieldValidator<DateTime?>? validator;

  @override
  State<AppDateTimePicker> createState() => _AppDateTimePickerState();
}

class _AppDateTimePickerState extends State<AppDateTimePicker> {
  final _fieldKey = GlobalKey<FormFieldState<DateTime>>();

  @override
  void didUpdateWidget(AppDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fieldKey.currentState?.didChange(widget.selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      key: _fieldKey,
      initialValue: widget.selected,
      validator: widget.validator,
      builder: (fieldState) {
        final formattedValue = fieldState.value != null
            ? DateFormat(widget.formatPattern).format(fieldState.value!)
            : null;

        return InkWell(
          onTap: () async {
            final now = DateTime.now();
            final initial = fieldState.value ?? now;
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: now.subtract(const Duration(days: 365 * 10)),
              lastDate: now.add(const Duration(days: 365 * 10)),
            );

            if (pickedDate == null || !context.mounted) return;

            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(initial),
            );

            final newDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime?.hour ?? 0,
              pickedTime?.minute ?? 0,
            );

            fieldState.didChange(newDateTime);
            widget.onChanged?.call(newDateTime);
          },
          borderRadius:
              widget.style == AppFieldStyle.normal || widget.style == AppFieldStyle.normalCompact
              ? BorderRadius.circular(16)
              : null,
          child: Stack(
            children: [
              InputDecorator(
                decoration: widget.style.getInputDecoration(
                  base: InputDecoration(
                    labelText: widget.labelText,
                    errorText: fieldState.errorText,
                  ),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    const Icon(
                      SolarIconsOutline.calendar,
                      color: ColorName.labelSecondary,
                      size: 18,
                    ),
                    Expanded(
                      child: Text(
                        formattedValue ?? widget.hintText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fieldState.value != null
                              ? ColorName.labelPrimary
                              : ColorName.labelSecondary,
                        ),
                      ),
                    ),
                    const SizedBox.square(dimension: 24),
                  ],
                ),
              ),
              if (fieldState.value != null)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      color: ColorName.labelSecondary,
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        fieldState.didChange(null);
                        widget.onChanged?.call(null);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
