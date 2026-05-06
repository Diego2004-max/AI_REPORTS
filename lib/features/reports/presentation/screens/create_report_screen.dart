import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/features/reports/presentation/screens/create_audio_report_screen.dart';
import 'package:reportes_ai/features/reports/presentation/screens/create_written_report_screen.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';

class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});

  void _openWritten(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateWrittenReportScreen()),
    );
  }

  void _openAudio(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAudioReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Crear reporte',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo quieres reportar?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Elige el tipo de reporte que deseas enviar.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppCard(
                        radius: 24,
                        onTap: () => _openWritten(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Reporte escrito',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Opción para escribir manualmente el incidente.',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _FlowPoint(text: 'Título obligatorio'),
                            const _FlowPoint(text: 'Categoría obligatoria'),
                            const _FlowPoint(text: 'Descripción opcional'),
                            const _FlowPoint(text: 'Ubicación obligatoria'),
                            const _FlowPoint(text: 'Imagen opcional'),
                            const SizedBox(height: 20),
                            PrimaryButton(
                              label: 'Continuar con reporte escrito',
                              onPressed: () => _openWritten(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        radius: 24,
                        onTap: () => _openAudio(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.mic_none_rounded,
                                color: AppColors.muted,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Reporte por audio',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Opción para enviar evidencia por audio.',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _FlowPoint(text: 'Título obligatorio'),
                            const _FlowPoint(text: 'Categoría obligatoria'),
                            const _FlowPoint(text: 'Audio obligatorio'),
                            const _FlowPoint(text: 'Ubicación obligatoria'),
                            const _FlowPoint(text: 'Imagen opcional'),
                            const _FlowPoint(text: 'Descripción opcional'),
                            const SizedBox(height: 20),
                            PrimaryButton(
                              label: 'Continuar con reporte por audio',
                              onPressed: () => _openAudio(context),
                              ghost: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowPoint extends StatelessWidget {
  final String text;
  const _FlowPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.faint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
