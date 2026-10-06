import 'package:gp1/core/ui/go_dropdown/go_dropdown.dart';

/// A choice of an `AppDropdown` that carries its own label, so the list can hold entries such as
/// "All", whose [value] is null and stands for no filter. Two options are equal when their values
/// are, which is how the dropdown marks the selected one.
class AppOption<T> with GoDropdownDisplayText {
  const AppOption(this.value, this.label);

  final T? value;
  final String label;

  @override
  String get displayText => label;

  @override
  bool operator ==(Object other) => other is AppOption<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
