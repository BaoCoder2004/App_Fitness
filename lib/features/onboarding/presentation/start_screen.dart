import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_fitness/core/constants/app_images.dart';
import 'package:app_fitness/features/auth/presentation/register_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HERO FULL-WIDTH, BO GÓC DƯỚI, DÙNG ẢNH
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: SizedBox(
                width: double.infinity,
                height: size.height * 0.45, // ~45% chiều cao màn
                child: Image.asset(
                  AppImages.onboardingHero, // assets/images/onboarding_hero.png
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // TEXT + BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rèn luyện thông minh, sống khoẻ mỗi ngày',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      textStyle: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Theo dõi rèn luyện sức khoẻ và gợi ý cá nhân hoá cho riêng bạn.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'BẮT ĐẦU',
                        style: GoogleFonts.inter(
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
