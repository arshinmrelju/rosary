import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../domain/models/prayer_intention.dart';
import 'intention_controller.dart';

/// Submit and browse prayer intentions.
class IntentionScreen extends StatefulWidget {
  const IntentionScreen({super.key});

  @override
  State<IntentionScreen> createState() => _IntentionScreenState();
}

class _IntentionScreenState extends State<IntentionScreen> {
  IntentionController? _controller;
  bool _wired = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    _controller ??= IntentionController(deps);
    if (!_wired) {
      _wired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller!.load());
    }

    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) {
        final c = _controller!;

        return SafeArea(
          child: AppContentFrame(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: <Widget>[
                Text(
                  'Prayer Intentions',
                  style: context.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave an intention. The community carries it through the day.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                _SubmitCard(controller: c),
                const SizedBox(height: AppSpacing.xxl),

                Text(
                  'Community intentions',
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                _CommunityList(controller: c),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubmitCard extends StatefulWidget {
  const _SubmitCard({required this.controller});

  final IntentionController controller;

  @override
  State<_SubmitCard> createState() => _SubmitCardState();
}

class _SubmitCardState extends State<_SubmitCard> {
  final TextEditingController _text = TextEditingController();
  bool _anonymous = true;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;

    final ok = await widget.controller.submit(
      PrayerIntention(
        text: text,
        anonymous: _anonymous,
        approved: false,
      ),
    );
    if (ok && mounted) {
      _text.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intention submitted. Thank you.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Share an intention',
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _text,
            maxLines: 3,
            maxLength: 280,
            decoration: const InputDecoration(
              hintText: 'Who or what should the community pray for?',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Checkbox(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v ?? true),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Submit anonymously', style: context.textTheme.bodyMedium),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: widget.controller.isSubmitting ? null : _submit,
            icon: const Icon(Icons.favorite_outline, size: 20),
            label: Text(
              widget.controller.isSubmitting ? 'Submitting…' : 'Submit intention',
            ),
          ),
          if (widget.controller.submitError != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.controller.submitError!,
              style: context.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommunityList extends StatelessWidget {
  const _CommunityList({required this.controller});

  final IntentionController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const AppLoadingView(message: 'Loading intentions…');
    }
    if (controller.error != null) {
      return AppErrorView(message: controller.error!, onRetry: controller.load);
    }
    if (controller.intentions.isEmpty) {
      return const AppEmptyView(
        icon: Icons.favorite_border,
        message: 'No intentions shared yet. Be the first.',
      );
    }

    return Column(
      children: <Widget>[
        for (final intention in controller.intentions) ...<Widget>[
          _IntentionTile(intention: intention),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _IntentionTile extends StatelessWidget {
  const _IntentionTile({required this.intention});

  final PrayerIntention intention;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.marianBlueSoft,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.favorite,
              size: 16,
              color: AppColors.marianBlue,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(intention.text, style: context.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${intention.prayerCount} prayer${intention.prayerCount == 1 ? '' : 's'}',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}