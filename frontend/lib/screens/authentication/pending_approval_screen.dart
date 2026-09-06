import 'package:campuslink/app_theme.dart';
import 'package:flutter/material.dart';

/// Shown after successful registration that requires admin approval.
class PendingApprovalScreen extends StatelessWidget {
  final String userType;
  final String institution;
  final String? email;

  const PendingApprovalScreen({
    super.key,
    required this.userType,
    required this.institution,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Gradient hero
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      boxShadow: AppTheme.softShadow(AppTheme.brandIndigo),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hourglass_top_rounded,
                              size: 52, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Registration received!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardBox(theme, radius: AppTheme.radiusL),
                    child: Column(
                      children: [
                        Text(
                          'Your $userType account is waiting for approval by the $institution admin.',
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (email != null && email!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            email!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: (theme.brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black)
                                  .withOpacity(0.55),
                            ),
                          ),
                        ],
                        const Divider(height: 32),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.infoColor.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusS),
                              ),
                              child: const Icon(Icons.info_outline_rounded,
                                  color: AppTheme.infoColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You will be able to log in as soon as your registration is approved.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.popUntil(context, (r) => r.isFirst),
                            child: const Text('Back to Home'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
