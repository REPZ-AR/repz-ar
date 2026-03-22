import 'package:flutter/material.dart';
import 'package:repz/model/equipment_details.dart';
import 'package:repz/model/tutorial.dart';
import 'package:repz/repositories/equipment_catalog_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class EquipmentOverlay extends StatefulWidget {
  const EquipmentOverlay({
    super.key,
    required this.equipmentName,
    this.confidence,
    EquipmentCatalogRepository? repository,
  }) : _repository = repository;

  final String equipmentName;
  final double? confidence;
  final EquipmentCatalogRepository? _repository;

  @override
  State<EquipmentOverlay> createState() => _EquipmentOverlayState();
}

class _EquipmentOverlayState extends State<EquipmentOverlay>
    with SingleTickerProviderStateMixin {
  late final EquipmentCatalogRepository _repository =
      widget._repository ?? EquipmentCatalogRepository();
  late final Future<EquipmentDetails?> _detailsFuture =
      _repository.fetchEquipmentDetailsByName(widget.equipmentName);
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _fadeAnimation = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
    CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openTutorial(Tutorial tutorial) async {
    final uri = Uri.tryParse(tutorial.tutorialLink);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open tutorial link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final confidence = widget.confidence;
    final confidenceText =
        confidence == null
            ? null
            : 'Confidence ${(confidence * 100).clamp(0, 100).toStringAsFixed(1)}%';

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.equipmentName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (confidenceText != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        confidenceText,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<EquipmentDetails?>(
                future: _detailsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState(theme, colorScheme);
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(theme);
                  }

                  final details = snapshot.data;
                  final muscles = details?.muscleGroups ?? const [];
                  final tutorials = details?.tutorials ?? const [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          theme: theme,
                          title: 'Targeting muscle groups',
                          icon: Icons.fitness_center,
                          child:
                              muscles.isEmpty
                                  ? Text(
                                    'No muscle mapping found for this equipment yet.',
                                    style: theme.textTheme.bodyMedium,
                                  )
                                  : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        muscles
                                            .map(
                                              (muscle) => Chip(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6,
                                                    ),
                                                avatar: const Icon(
                                                  Icons.bolt,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  '${muscle.muscleGroupName}  ${muscle.muscleClass.toUpperCase()}',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          theme: theme,
                          title: 'Tutorials',
                          icon: Icons.play_circle_outline,
                          child:
                              tutorials.isEmpty
                                  ? Text(
                                    'No tutorials found for this equipment yet.',
                                    style: theme.textTheme.bodyMedium,
                                  )
                                  : Column(
                                    children:
                                        tutorials
                                            .map(
                                              (tutorial) => Card(
                                                elevation: 0,
                                                margin: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                color:
                                                    colorScheme
                                                        .surfaceContainerLowest,
                                                child: ListTile(
                                                  minVerticalPadding: 12,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                  title: Text(
                                                    tutorial.description,
                                                  ),
                                                  trailing: const Icon(
                                                    Icons.open_in_new,
                                                  ),
                                                  onTap:
                                                      () => _openTutorial(
                                                        tutorial,
                                                      ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
        ),
      );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LinearProgressIndicator(
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading equipment details...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fetching target muscles and tutorials for this machine.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Text(
        'Could not load equipment details right now.',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
