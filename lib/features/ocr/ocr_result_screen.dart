import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'ocr_providers.dart';

/// Affichage du texte OCR avec actions de copie / effacement.
class OcrResultScreen extends ConsumerWidget {
  const OcrResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(ocrExtractedTextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat du scan'),
        actions: [
          if (text.isNotEmpty)
            IconButton(
              tooltip: 'Copier',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Texte copié dans le presse-papiers'),
                  ),
                );
              },
            ),
        ],
      ),
      body: text.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.text_snippet_outlined,
                    size: 48,
                    color: AppColors.brownMedium.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun texte pour le moment.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.brownDark.withValues(alpha: 0.65),
                        ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.nude,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.brownLight.withValues(alpha: 0.55),
                  ),
                ),
                child: SelectableText(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                        color: AppColors.brownDark,
                      ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: OutlinedButton(
            onPressed: () {
              ref.read(ocrExtractedTextProvider.notifier).state = '';
              Navigator.of(context).pop();
            },
            child: const Text('Effacer et fermer'),
          ),
        ),
      ),
    );
  }
}
