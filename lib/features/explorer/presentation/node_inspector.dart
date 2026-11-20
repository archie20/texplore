import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/evidence_style.dart';
import '../../../app/theme/stage_style.dart';
import '../../../domain/enums/evidence_status.dart';
import '../../../domain/enums/research_stage.dart';
import '../../../domain/models/candidate.dart';
import '../../../domain/models/catalogue.dart';
import '../../../domain/models/research_node.dart';
import '../../../domain/services/graph_queries.dart';
import '../../comparison/comparison_cubit.dart';
import '../application/catalogue_cubit.dart';
import '../application/explorer_bloc.dart';
import '../application/explorer_event.dart';
import '../application/explorer_state.dart';
import 'detail_focus.dart';
import 'publication_detail.dart';

/// The words a selected circle speaks, set on the paper under its label.
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({
    required this.detailOpen,
    required this.onToggle,
    super.key,
  });

  final bool detailOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExplorerBloc, ExplorerState>(
      buildWhen: (previous, next) =>
          previous.selectedNodeId != next.selectedNodeId ||
          previous.selectedCandidateId != next.selectedCandidateId,
      builder: (context, state) {
        final loaded = context.read<CatalogueCubit>().state;
        if (loaded is! CatalogueLoaded) return const SizedBox.shrink();
        final catalogue = loaded.catalogue;
        final node = state.selectedNodeId == null
            ? null
            : catalogue.nodes[state.selectedNodeId!];
        final candidate = catalogue.candidateById(
          node?.candidateId ?? state.selectedCandidateId ?? '',
        );
        final index = candidate == null
            ? 0
            : catalogue.candidates.indexWhere(
                (item) => item.id == candidate.id,
              );
        final tick = context.notebook.tickFor(index < 0 ? 0 : index);
        final Widget body;
        if (node != null) {
          body = _NodeNote(
            catalogue: catalogue,
            node: node,
            tick: tick,
            detailOpen: detailOpen,
            onToggle: onToggle,
          );
        } else if (candidate != null) {
          body = _CandidateNote(
            candidate: candidate,
            tick: tick,
            detailOpen: detailOpen,
            onToggle: onToggle,
          );
        } else {
          body = const _Quiet('Select a thesis problem or a record.');
        }
        return ColoredBox(color: context.notebook.canvas, child: body);
      },
    );
  }
}

class _NodeNote extends StatelessWidget {
  const _NodeNote({
    required this.catalogue,
    required this.node,
    required this.tick,
    required this.detailOpen,
    required this.onToggle,
  });

  final Catalogue catalogue;
  final ResearchNode node;
  final Color tick;
  final bool detailOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final focus = DetailScope.of(context);
    final publicationId = focus.nodeId == node.id ? focus.publicationId : null;
    final publication = publicationId == null
        ? null
        : catalogue.publications[publicationId];
    final border = evidenceBorderFor(node.evidenceStatus);
    final links = catalogue.evidenceForNode(node.id);
    final parent = node.parentId == null
        ? null
        : catalogue.nodes[node.parentId!];
    final children = GraphQueries.children(catalogue, node);
    final reviewing = links.isEmpty && _awaitingEvidence(node);
    final hasMore =
        node.detail.trim().isNotEmpty ||
        node.assumptions.isNotEmpty ||
        node.risks.isNotEmpty ||
        node.validationRequirements.isNotEmpty ||
        node.notes.isNotEmpty ||
        links.isNotEmpty ||
        parent != null ||
        children.isNotEmpty ||
        (node.lastReviewed ?? '').isNotEmpty;
    final longer = publication != null
        ? PublicationDetail(
            publication: publication,
            ruleColor: tick,
            onBack: focus.clearPublication,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (node.detail.trim().isNotEmpty)
                _section(context, null, paragraph: node.detail),
              if (node.assumptions.isNotEmpty)
                _section(context, 'Assumptions', items: node.assumptions),
              if (node.risks.isNotEmpty)
                _section(context, 'Risks', items: node.risks),
              if (node.validationRequirements.isNotEmpty)
                _section(
                  context,
                  'Validation still required',
                  items: node.validationRequirements,
                ),
              if (node.notes.isNotEmpty)
                _section(context, 'Notes', items: node.notes),
              if (links.isNotEmpty)
                for (final link in links)
                  _ClaimBlock(
                    catalogue: catalogue,
                    node: node,
                    linkId: link.id,
                  ),
              if (parent != null)
                _Follow(
                  label: 'Follows from ${parent.title}',
                  onTap: () => _openNode(context, parent.id),
                ),
              for (final child in children)
                _Follow(
                  label: 'Leads to ${child.title}',
                  onTap: () => _openNode(context, child.id),
                ),
              if ((node.lastReviewed ?? '').isNotEmpty)
                _section(
                  context,
                  null,
                  paragraph: 'Reviewed ${node.lastReviewed}',
                ),
            ],
          );
    final meta = <String>[
      StageStyle.of(node.stage).label,
      node.evidenceStatus.label,
      if (node.gapStrength != null) node.gapStrength!.label,
      if ((node.priority ?? '').isNotEmpty) node.priority!,
    ];
    return _spoken(
      detailOpen: detailOpen,
      hasMore: hasMore,
      onToggle: onToggle,
      longer: _Bloom(child: longer),
      words: [
        _Title(node.title, size: 18),
        const SizedBox(height: 8),
        _EvidenceRule(color: tick, border: border),
        const SizedBox(height: 8),
        _Meta(meta.join(' · ')),
        if (node.summary.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _Body(node.summary),
        ],
        if (reviewing) ...[
          const SizedBox(height: 10),
          const _Quiet(
            'Evidence still being reviewed. No publication is linked to this record yet.',
          ),
        ],
      ],
    );
  }

  void _openNode(BuildContext context, String id) {
    final bloc = context.read<ExplorerBloc>();
    bloc.add(PathRevealed(id));
    bloc.add(NodeSelected(id, centre: true));
  }
}

bool _awaitingEvidence(ResearchNode node) {
  return node.stage == ResearchStage.literatureGaps ||
      node.evidenceStatus == EvidenceStatus.needsLiterature;
}

class _CandidateNote extends StatelessWidget {
  const _CandidateNote({
    required this.candidate,
    required this.tick,
    required this.detailOpen,
    required this.onToggle,
  });

  final Candidate candidate;
  final Color tick;
  final bool detailOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final compared = context.watch<ComparisonCubit>().state.contains(
      candidate.id,
    );
    final hasMore =
        _filled(candidate.technicalContribution) ||
        _filled(candidate.ghanaianRelevance) ||
        _filled(candidate.dataRequirements) ||
        _filled(candidate.evaluationDesign) ||
        candidate.feasibility != null ||
        candidate.majorRisks.isNotEmpty ||
        candidate.readiness.isNotEmpty ||
        candidate.openDecisions.isNotEmpty;
    final details = <Widget>[
      if (_filled(candidate.technicalContribution))
        _section(
          context,
          'Technical contribution',
          paragraph: candidate.technicalContribution!,
        ),
      if (_filled(candidate.ghanaianRelevance))
        _section(
          context,
          'Ghanaian relevance',
          paragraph: candidate.ghanaianRelevance!,
        ),
      if (_filled(candidate.dataRequirements))
        _section(
          context,
          'Data and resources',
          paragraph: candidate.dataRequirements!,
        ),
      if (_filled(candidate.evaluationDesign))
        _section(
          context,
          'Evaluation design',
          paragraph: candidate.evaluationDesign!,
        ),
      if (candidate.feasibility != null) ...[
        _section(
          context,
          'Feasibility',
          paragraph:
              '${candidate.feasibility!.rating}. ${candidate.feasibility!.rationale}',
        ),
        const _Quiet('Planning assessment, not a measured score.'),
      ],
      if (candidate.majorRisks.isNotEmpty)
        _section(context, 'Major risks', items: candidate.majorRisks),
      if (candidate.readiness.isNotEmpty) ...[
        _section(context, 'Readiness'),
        const _Quiet('A checklist, not a score.'),
        for (final check in candidate.readiness)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _Body(
              '${check.met ? 'Met' : 'Not yet'}. ${check.label}'
              '${check.note.isEmpty ? '' : ' ${check.note}'}',
            ),
          ),
      ],
      if (candidate.openDecisions.isNotEmpty)
        _section(context, 'Open decisions', items: candidate.openDecisions),
    ];
    return _spoken(
      detailOpen: detailOpen,
      hasMore: hasMore,
      onToggle: onToggle,
      pinned: _WordButton(
        label: compared ? 'Remove from comparison' : 'Add to comparison',
        onTap: () => context.read<ComparisonCubit>().toggle(candidate.id),
      ),
      longer: _Bloom(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: details,
        ),
      ),
      words: [
        _Title(candidate.title, size: 18),
        const SizedBox(height: 8),
        _EvidenceRule(color: tick, border: EvidenceBorder.solid),
        const SizedBox(height: 8),
        _Meta('${candidate.priority.label} · ${candidate.maturity.label}'),
        if (candidate.summary.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _Body(candidate.summary),
        ],
      ],
    );
  }
}

/// The first words stay near the circle. More stays in that block, and the
/// longer note scrolls inside it.
Widget _spoken({
  required List<Widget> words,
  required bool detailOpen,
  required bool hasMore,
  required VoidCallback onToggle,
  required Widget longer,
  Widget? pinned,
}) {
  return ConstrainedBox(
    constraints: BoxConstraints(maxHeight: detailOpen ? 300 : 188),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            key: detailOpen ? const Key('circle-speech') : null,
            primary: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [...words, if (detailOpen) longer],
            ),
          ),
        ),
        if (pinned != null || hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ?pinned,
                if (hasMore) ...[
                  if (pinned != null) const SizedBox(height: 8),
                  _WordButton(
                    key: const Key('note-more'),
                    label: detailOpen ? 'Less' : 'More',
                    onTap: onToggle,
                  ),
                ],
              ],
            ),
          ),
      ],
    ),
  );
}

class _ClaimBlock extends StatelessWidget {
  const _ClaimBlock({
    required this.catalogue,
    required this.node,
    required this.linkId,
  });

  final Catalogue catalogue;
  final ResearchNode node;
  final String linkId;

  @override
  Widget build(BuildContext context) {
    final link = catalogue.evidenceLinks[linkId];
    if (link == null) {
      return const _Section(
        label: 'Evidence',
        child: _Quiet('This evidence link is missing from the catalogue.'),
      );
    }
    final publication = catalogue.publications[link.publicationId];
    final detail = [
      '${link.relationship.label} · ${link.evidenceStrength.label} · ${link.verificationStatus.label}',
      if ((link.limitation ?? '').trim().isNotEmpty) link.limitation!.trim(),
      if ((link.pageOrSection ?? '').trim().isNotEmpty)
        link.pageOrSection!.trim(),
      if ((link.notes ?? '').trim().isNotEmpty) link.notes!.trim(),
    ];
    return _Section(
      label: 'Evidence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Body(link.claim),
          const SizedBox(height: 6),
          _Quiet(detail.join('\n')),
          const SizedBox(height: 8),
          if (publication == null)
            const _Quiet('The linked publication record is missing.')
          else
            _WordButton(
              label: publication.citationLabel,
              onTap: () =>
                  DetailScope.of(context)
                      .open(nodeId: node.id, publicationId: publication.id),
            ),
        ],
      ),
    );
  }
}

/// The longer note grows out of the circle the way a child does.
class _Bloom extends StatefulWidget {
  const _Bloom({required this.child});

  final Widget child;

  @override
  State<_Bloom> createState() => _BloomState();
}

class _BloomState extends State<_Bloom> with SingleTickerProviderStateMixin {
  late final AnimationController _bloom;

  @override
  void initState() {
    super.initState();
    _bloom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _bloom.value = 1;
      return;
    }
    if (!_bloom.isAnimating && _bloom.value == 0) _bloom.forward();
  }

  @override
  void dispose() {
    _bloom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bloom,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_bloom.value);
        return Opacity(
          opacity: 0.2 + 0.8 * t,
          child: Transform.scale(
            scale: 0.2 + 0.8 * t,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.low,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.size = 22});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: serifFamily,
        fontSize: size,
        height: 1.25,
        fontWeight: FontWeight.w500,
        color: context.notebook.ink,
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: sansFamily,
        fontSize: 12,
        height: 1.4,
        color: context.theme.colors.mutedForeground,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: sansFamily,
        fontSize: 14,
        height: 1.5,
        color: context.theme.colors.foreground,
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: sansFamily,
        fontSize: 13,
        height: 1.45,
        color: context.theme.colors.mutedForeground,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.label});

  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                fontFamily: sansFamily,
                fontSize: 12,
                height: 1.4,
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 4),
          ],
          child,
        ],
      ),
    );
  }
}

class _Follow extends StatelessWidget {
  const _Follow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _WordButton(label: label, onTap: onTap),
    );
  }
}

class _WordButton extends StatelessWidget {
  const _WordButton({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          button: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: sansFamily,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: context.notebook.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidenceRule extends StatelessWidget {
  const _EvidenceRule({required this.color, required this.border});

  final Color color;
  final EvidenceBorder border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _RulePainter(color: color, border: border),
      ),
    );
  }
}

class _RulePainter extends CustomPainter {
  const _RulePainter({required this.color, required this.border});

  final Color color;
  final EvidenceBorder border;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.butt;
    final y = size.height / 2;
    if (border == EvidenceBorder.solid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    final dash = border == EvidenceBorder.dotted ? 1.6 : 5.0;
    final gap = border == EvidenceBorder.dotted ? 3.0 : 3.5;
    var x = 0.0;
    while (x < size.width) {
      final end = x + dash > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_RulePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.border != border;
  }
}

Widget _section(
  BuildContext context,
  String? label, {
  String? paragraph,
  List<String>? items,
}) {
  return _Section(
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (paragraph != null) _Body(paragraph),
        if (items != null)
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(
                top: i == 0 && paragraph == null ? 0 : 8,
              ),
              child: _Body(items[i]),
            ),
      ],
    ),
  );
}

bool _filled(String? value) => value != null && value.trim().isNotEmpty;
