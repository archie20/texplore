import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app/breakpoints.dart';
import '../../domain/services/comparison_service.dart';
import '../explorer/application/catalogue_cubit.dart';
import 'comparison_cubit.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({this.initialIds = '', super.key});

  final String initialIds;

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  @override
  void initState() {
    super.initState();
    final ids = [
      for (final id in widget.initialIds.split(','))
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (ids.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ComparisonCubit>().setIds(ids);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogueState = context.watch<CatalogueCubit>().state;
    final ids = context.watch<ComparisonCubit>().state;
    if (catalogueState is! CatalogueLoaded) {
      return const ColoredBox(
        color: Color(0xFFFAF9F6),
        child: Center(child: Text('Loading catalogue')),
      );
    }
    final columns = const ComparisonService().compare(
      catalogueState.catalogue,
      ids,
    );
    return ColoredBox(
      color: context.theme.colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                FButton(
                  variant: .ghost,
                  size: .sm,
                  onPress: () => context.go('/'),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Comparison',
                    style: context.theme.typography.display.sm.copyWith(
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Aligned fields only. Missing information is labelled, and nothing here is a score or a ranking.',
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: columns.length < 2
                ? const _NeedTwo()
                : _Table(
                    columns: columns,
                    narrow: AppBreakpoint.of(MediaQuery.sizeOf(context).width)
                        .isMobile,
                  ),
          ),
        ],
      ),
    );
  }
}

class _NeedTwo extends StatelessWidget {
  const _NeedTwo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose at least two candidates.',
            style: context.theme.typography.body.md,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add them from a candidate overview, then open this page again.',
          ),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.columns, required this.narrow});

  final List<ComparisonColumn> columns;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    if (narrow) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final column in columns) ...[
            Text(
              column.candidate.title,
              style: context.theme.typography.display.sm.copyWith(fontSize: 18),
            ),
            for (final cell in column.cells)
              _CellView(column: column, cell: cell),
            const SizedBox(height: 20),
          ],
        ],
      );
    }
    final labels = columns.first.cells.map((cell) => cell.label).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 180),
            for (final column in columns)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    column.candidate.shortTitle,
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var row = 0; row < labels.length; row++)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    labels[row],
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
                for (final column in columns)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _CellView(
                        column: column,
                        cell: column.cells[row],
                        showLabel: false,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CellView extends StatelessWidget {
  const _CellView({
    required this.column,
    required this.cell,
    this.showLabel = true,
  });

  final ComparisonColumn column;
  final ComparisonCell cell;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final body = Text(
      cell.value,
      style: context.theme.typography.body.sm.copyWith(
        color: cell.missing
            ? context.theme.colors.mutedForeground
            : context.theme.colors.foreground,
      ),
    );
    final content = cell.nodeId == null
        ? body
        : GestureDetector(
            onTap: () => context.go(
              '/?candidate=${column.candidate.id}&node=${cell.nodeId}',
            ),
            child: body,
          );
    if (!showLabel) return content;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cell.label,
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          content,
        ],
      ),
    );
  }
}
