import 'package:flutter/material.dart';
import 'package:gp1/core/utils/extensions/date_time_extension.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/models/app_field_style.dart';
import 'package:solar_icons/solar_icons.dart';

class AppDateRangePicker extends StatefulWidget {
  const AppDateRangePicker({
    super.key,
    this.style = AppFieldStyle.normal,
    this.selected,
    this.labelText,
    this.hintText = 'Tất cả thời gian',
    this.onChanged,
    this.validator,
  });

  final AppFieldStyle style;
  final DateTimeRange? selected;
  final String? labelText;
  final String hintText;
  final ValueChanged<DateTimeRange?>? onChanged;
  final FormFieldValidator<DateTimeRange?>? validator;

  @override
  State<AppDateRangePicker> createState() => _AppDateRangePickerState();
}

class _AppDateRangePickerState extends State<AppDateRangePicker> {
  final _fieldKey = GlobalKey<FormFieldState<DateTimeRange>>();

  @override
  void didUpdateWidget(AppDateRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fieldKey.currentState?.didChange(widget.selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTimeRange>(
      key: _fieldKey,
      initialValue: widget.selected,
      validator: widget.validator,
      builder: (fieldState) {
        return InkWell(
          onTap: () async {
            final now = DateTime.now();
            final pickedRange = await showDateRangePicker(
              context: context,
              initialDateRange: fieldState.value,
              firstDate: now.subtract(const Duration(days: 365 * 10)),
              lastDate: now.add(const Duration(days: 365 * 10)),
            );

            if (pickedRange != null) {
              final newDateRange = DateTimeRange(
                start: pickedRange.start.startOfDay,
                end: pickedRange.end.endOfDay,
              );
              fieldState.didChange(newDateRange);
              widget.onChanged?.call(newDateRange);
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
