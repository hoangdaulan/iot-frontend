import 'package:flutter/material.dart';
import 'package:gp1/core/utils/extensions/date_time_extension.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/models/app_field_style.dart';
import 'package:solar_icons/solar_icons.dart';

class AppDatePicker extends StatefulWidget {
  const AppDatePicker({
    super.key,
    this.style = AppFieldStyle.normal,
    this.selected,
    this.labelText,
    this.hintText = 'Chọn ngày',
    this.onChanged,
    this.validator,
  });

  final AppFieldStyle style;
  final DateTime? selected;
  final String? labelText;
  final String hintText;
  final ValueChanged<DateTime?>? onChanged;
  final FormFieldValidator<DateTime?>? validator;

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  final _fieldKey = GlobalKey<FormFieldState<DateTime>>();

  @override
  void didUpdateWidget(AppDatePicker oldWidget) {
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
        return InkWell(
          onTap: () async {
            final now = DateTime.now();
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: fieldState.value,
              firstDate: now.subtract(const Duration(days: 365 * 10)),
              lastDate: now.add(const Duration(days: 365 * 10)),
            );

            if (pickedDate != null) {
              final startOfDay = pickedDate.startOfDay;
              fieldState.didChange(startOfDay);
              widget.onChanged?.call(startOfDay);
            }
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
                        fieldState.value?.toFormatString() ?? widget.hintText,
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
