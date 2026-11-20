import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../../app/open_link.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/evidence_style.dart';
import '../../../domain/enums/verification_status.dart';
import '../../../domain/models/publication.dart';

class PublicationDetail extends StatefulWidget {
  const PublicationDetail({
    required this.publication,
    required this.onBack,
    required this.ruleColor,
    super.key,
  });

  final Publication publication;
  final VoidCallback onBack;
  final Color ruleColor;

  @override
  State<PublicationDetail> createState() => _PublicationDetailState();
}

class _PublicationDetailState extends State<PublicationDetail> {
  var _linkFailed = false;

  @override
  Widget build(BuildContext context) {
    final publication = widget.publication;
    final muted = context.theme.colors.mutedForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Action(label: 'Back', onTap: widget.onBack),
        const SizedBox(height: 12),
        Text(
          publication.citationLabel,
          style: TextStyle(
            fontFamily: serifFamily,
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w500,
            color: context.notebook.ink,
          ),
        ),
        const SizedBox(height: 10),
        _PublicationRule(
          color: widget.ruleColor,
          border: _borderFor(publication.verificationStatus),
        ),
        const SizedBox(height: 10),
        Text(
          '${publication.publicationType.label} · ${publication.verificationStatus.label}',
          style: TextStyle(
            fontFamily: sansFamily,
            fontSize: 12,
            height: 1.4,
            color: muted,
          ),
        ),
        for (final line in _recorded(publication))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: line.mono
                ? Text(
                    line.text,
                    style: TextStyle(
                      fontFamily: monoFamily,
                      fontSize: 12,
                      height: 1.4,
                      color: context.theme.colors.foreground,
                    ),
                  )
                : Text(
                    line.text,
                    style: TextStyle(
                      fontFamily: sansFamily,
                      fontSize: 14,
                      height: 1.5,
                      color: context.theme.colors.foreground,
                    ),
                  ),
          ),
        if (publication.externalUri == null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              'No external link is recorded for this source.',
              style: TextStyle(
                fontFamily: sansFamily,
                fontSize: 13,
                height: 1.45,
                color: muted,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 16),
          _Action(
            label: 'Open the source',
            onTap: () async {
              final opened = await openExternal(publication.externalUri);
              if (!opened && mounted) setState(() => _linkFailed = true);
            },
          ),
        ],
        if (_linkFailed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'This link could not be opened.',
              style: TextStyle(
                fontFamily: sansFamily,
                fontSize: 13,
                height: 1.45,
                color: muted,
              ),
            ),
          ),
      ],
    );
  }
}

class _Recorded {
  const _Recorded(this.text, {this.mono = false});

  final String text;
  final bool mono;
}

List<_Recorded> _recorded(Publication publication) {
  final lines = <_Recorded>[];
  void add(String label, String? value, {bool mono = false}) {
    if (value == null || value.trim().isEmpty) return;
    lines.add(_Recorded('$label  ${value.trim()}', mono: mono));
  }

  add('Venue', publication.venue);
  add('Volume', publication.volume);
  add('Issue', publication.issue);
  add('Pages', publication.pages);
  add('DOI', publication.doi, mono: true);
  add('URL', publication.url, mono: true);
  add('Accessed', publication.accessDate);
  if ((publication.verificationNotes ?? '').trim().isNotEmpty) {
    lines.add(_Recorded(publication.verificationNotes!.trim()));
  }
  if ((publication.abstractText ?? '').trim().isNotEmpty) {
    lines.add(_Recorded(publication.abstractText!.trim()));
  }
  if ((publication.relevanceNote ?? '').trim().isNotEmpty) {
    lines.add(_Recorded(publication.relevanceNote!.trim()));
  }
  if ((publication.researchMethod ?? '').trim().isNotEmpty) {
    lines.add(_Recorded(publication.researchMethod!.trim()));
  }
  if ((publication.keyFindings ?? '').trim().isNotEmpty) {
    lines.add(_Recorded(publication.keyFindings!.trim()));
  }
  if ((publication.limitations ?? '').trim().isNotEmpty) {
    lines.add(_Recorded(publication.limitations!.trim()));
  }
  return lines;
}

EvidenceBorder _borderFor(VerificationStatus status) {
  return switch (status) {
    VerificationStatus.verifiedFullText ||
    VerificationStatus.verifiedAbstract ||
    VerificationStatus.metadataVerified => EvidenceBorder.solid,
    VerificationStatus.disputed => EvidenceBorder.dotted,
    VerificationStatus.unverified ||
    VerificationStatus.notAccessible => EvidenceBorder.dashed,
  };
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.onTap});

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
    );
  }
}

class _PublicationRule extends StatelessWidget {
  const _PublicationRule({required this.color, required this.border});

  final Color color;
  final EvidenceBorder border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _PublicationRulePainter(color: color, border: border),
      ),
    );
  }
}

class _PublicationRulePainter extends CustomPainter {
  const _PublicationRulePainter({required this.color, required this.border});

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
  bool shouldRepaint(_PublicationRulePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.border != border;
  }
}
