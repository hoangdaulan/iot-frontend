import 'package:flutter/material.dart';
import 'package:go_table/go_table.dart';
import 'package:gp1/core/ui/animated_overlay/animated_overlay.dart';
import 'package:gp1/core/utils/extensions/widget_list_separator.dart';
import 'package:gp1/data/models/paged_list.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/table/app_table_column_filter.dart';
import 'package:gp1/presentation/widgets/table/app_table_select_config.dart';
import 'package:solar_icons/solar_icons.dart';

export 'package:gp1/presentation/widgets/table/app_table_column_filter.dart';
export 'package:gp1/presentation/widgets/table/app_table_select_config.dart';

class AppTableColumn<T> extends GoTableColumn<T> {
  AppTableColumn({
    super.headerLabel,
    Widget? header,
    this.filter,
    super.width,
    super.flex,
    required Widget Function(T data) cellBuilder,
  }) : super(
         header: (context) => _buildHeader(context, header, headerLabel, filter),
         cellBuilder: (_, data) => cellBuilder(data),
       );

  AppTableColumn.withIndex({
    super.headerLabel,
    Widget? header,
    this.filter,
    super.width,
    super.flex,
    required super.cellBuilder,
  }) : super(header: (context) => _buildHeader(context, header, headerLabel, filter));

  static Widget? _buildHeader(
    BuildContext context,
    Widget? header,
    String? label,
    AppTableColumnFilter? filter,
  ) {
    if (header != null) return header;
    if (filter == null) return null;
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        AnimatedOverlay(
          overlayWidth: 240,
          overlayDecoration: BoxDecoration(
            color: ColorName.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: (showOverlay) => IconButton(
            onPressed: showOverlay,
            constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
            iconSize: 18,
            color: filter.isActive ? ColorName.primary.withValues(alpha: 0.8) : null,
            icon: Icon(filter.isActive ? SolarIconsBold.filter : SolarIconsOutline.filter),
          ),
          overlay: (hideOverlay) => filter.overlay(context, hideOverlay),
        ),
      ],
    );
  }

  final AppTableColumnFilter? filter;
}

class AppTable<T> extends StatelessWidget {
  const AppTable({
    super.key,
    required this.pagedList,
    required this.minWidth,
    required this.columns,
    this.selectConfig,
    this.onRowTap,
    this.onCellKeyEvent,
    this.onRefresh,
    this.onRowsPerPageChanged,
    this.onPageChanged,
    this.rowBackgroundColor,
    this.dividerColor,
  }) : data = const [],
       showFooter = true;

  const AppTable.list({
    super.key,
    required this.data,
    required this.minWidth,
    required this.columns,
    this.selectConfig,
    this.onRowTap,
    this.onCellKeyEvent,
    this.rowBackgroundColor,
    this.dividerColor,
  }) : pagedList = const PagedList(),
       showFooter = false,
       onRefresh = null,
       onRowsPerPageChanged = null,
       onPageChanged = null;

  final PagedList<T> pagedList;
  final List<T> data;
  final bool showFooter;
  final double minWidth;
  final List<AppTableColumn<T>> columns;
  final AppTableSelectConfig<T>? selectConfig;
  final void Function(T data)? onRowTap;
  final GoTableCellKeyEventCallback<T>? onCellKeyEvent;
  final VoidCallback? onRefresh;
  final ValueChanged<int>? onRowsPerPageChanged;
  final ValueChanged<int>? onPageChanged;
  final Color? rowBackgroundColor;
  final Color? dividerColor;

  @override
  Widget build(BuildContext context) {
    final decoration = GoTableDecoration(
      rowBackgroundColor: rowBackgroundColor != null
          ? (index) => rowBackgroundColor!
          : GoTableDecoration.defaultRowBackgroundColor,
      dividerColor: dividerColor,
      focusColor: ColorName.primary.withValues(alpha: 0.2),
      filterIcon: SolarIconsOutline.sort,
      filterEnabledIcon: SolarIconsBold.sort,
      sortIcon: SolarIconsOutline.arrowDown,
      previousPageIcon: SolarIconsOutline.altArrowLeft,
      nextPageIcon: SolarIconsOutline.altArrowRight,
      emptyWidget: const Center(child: Text('Không có dữ liệu')),
    );

    final selectConfig = this.selectConfig;

    final actions = GoTableActions<T>(
      onRowTap: selectConfig != null ? selectConfig.onRowSelected : onRowTap,
      onCellKeyEvent: onCellKeyEvent,
      onRefresh: onRefresh,
      onRowsPerPageChanged: onRowsPerPageChanged,
      onPageChanged: onPageChanged,
    );

    final data = showFooter ? pagedList.data : this.data;

    final selectColumn = selectConfig != null
        ? AppTableColumn<T>(
            width: 48,
            cellBuilder: (item) => Center(
              child: IgnorePointer(
                child: SizedBox(
                  height: 24,
                  child: Checkbox(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    value: selectConfig.selectedItems.contains(item),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          )
        : null;

    final indexColumn = AppTableColumn<T>(
      headerLabel: 'STT',
      width: 48,
      cellBuilder: (item) => Center(child: Text((data.indexOf(item) + 1).toString())),
    );

    return Column(
      children: [
        if (selectConfig != null) ...[
          IntrinsicHeight(
            child: Row(
              children: [
                InkWell(
                  onTap: selectConfig.onSelectAll,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: IgnorePointer(
                          child: Checkbox(
                            value:
                                selectConfig.selectedItems.isNotEmpty &&
                                selectConfig.selectedItems.length == data.length,
                            onChanged: (_) {},
                          ),
                        ),
                      ),
                      const Text('Chọn tất cả'),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const VerticalDivider(),
                const Spacer(),
                const VerticalDivider(),
                ...selectConfig.actions?.separatedBy(const VerticalDivider()) ?? [],
              ],
            ),
          ),
          const Divider(),
        ],
        Expanded(
          child: GoTable<T>(
            data: data,
            minWidth: minWidth,
            columns: [?selectColumn, indexColumn, ...columns],
            showFooter: showFooter,
            rowsPerPage: pagedList.pageSize,
            currentPage: pagedList.page,
            totalPages: pagedList.pageCounts,
            actions: actions,
            decoration: decoration,
          ),
        ),
      ],
    );
  }
}
