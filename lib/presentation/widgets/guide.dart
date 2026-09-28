import 'package:flutter/material.dart';
import 'package:gp1/generated/colors.gen.dart';

class GuideSteps extends StatelessWidget {
  final int stepNumber;
  final String stepText;
  final String? imageUrl;
  final String? imageAsset;

  const GuideSteps({
    super.key,
    required this.stepNumber,
    required this.stepText,
    this.imageUrl,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepCircle(number: stepNumber),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    stepText,
                    style: const TextStyle(fontSize: 16.0, color: ColorName.labelSecondary),
                  ),
                ),
                if (imageUrl != null || imageAsset != null) const SizedBox(height: 12),
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                if (imageAsset != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imageAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
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

class _StepCircle extends StatelessWidget {
  final int number;
  const _StepCircle({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: ColorName.primary, shape: BoxShape.circle),
      child: Text(
        '$number',
        style: const TextStyle(color: ColorName.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String romanNumber;
  final String title;

  const SectionTitle({super.key, required this.romanNumber, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$romanNumber. $title',
      style: const TextStyle(fontSize: 18, color: ColorName.labelPrimary),
    );
  }
}
