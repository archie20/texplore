import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/catalogue.dart';

class ValidationPanel extends StatelessWidget {
  const ValidationPanel({required this.catalogue, super.key});

  final Catalogue catalogue;

  @override
  Widget build(BuildContext context) {
    final errors = [
      for (final issue in catalogue.issues)
        if (issue.isError) issue,
    ];
    final warnings = catalogue.warnings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Validation',
          style: context.theme.typography.display.sm.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'A candidate with blocking errors is left off the canvas. The others still render.',
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        if (catalogue.excluded.isEmpty && errors.isEmpty && warnings.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('No validation issues.'),
          ),
        for (final excluded in catalogue.excluded) ...[
          const SizedBox(height: 16),
          Text(
            excluded.title,
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Failed validation',
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.error,
            ),
          ),
          for (final issue in excluded.issues) _IssueLine(issue: issue),
        ],
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Other errors'),
          for (final issue in errors) _IssueLine(issue: issue),
        ],
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Warnings'),
          for (final issue in warnings) _IssueLine(issue: issue),
        ],
      ],
    );
  }
}

class _IssueLine extends StatelessWidget {
  const _IssueLine({required this.issue});

  final ValidationIssue issue;

  @override
  Widget build(BuildContext context) {
    final ids = [
      issue.candidateId,
      issue.nodeId,
      issue.publicationId,
      issue.evidenceLinkId,
    ].whereType<String>().join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(issue.message, style: context.theme.typography.body.sm),
          Text(
            ids.isEmpty ? issue.code : '${issue.code} · $ids',
            style: context.theme.typography.body.xs.copyWith(
              fontFamily: monoFamily,
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class FailedCatalogueScreen extends StatelessWidget {
  const FailedCatalogueScreen({
    required this.message,
    required this.issues,
    super.key,
  });

  final String message;
  final List<ValidationIssue> issues;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.theme.colors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'The catalogue could not be opened',
                style: context.theme.typography.display.md,
              ),
              const SizedBox(height: 8),
              Text(message, style: context.theme.typography.body.sm),
              const SizedBox(height: 12),
              for (final issue in issues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${issue.code}: ${issue.message}',
                    style: context.theme.typography.body.sm,
                  ),
                ),
              Text(
                'The catalogue files need to be corrected before the canvas can load.',
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
