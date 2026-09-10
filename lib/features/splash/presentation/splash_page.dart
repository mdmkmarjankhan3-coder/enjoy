import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/supabase_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _initTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    _initTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      try {
        if (SupabaseService.hasSession) {
          await SupabaseService.ensureProfileExists();
          if (mounted) context.go('/home');
        } else {
          if (mounted) context.go('/login');
        }
      } catch (_) {
        if (mounted) context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 140,
              height: 140,
              errorBuilder: (_, __, ___) => const Text(
                '🌟 ENJOY',
                style: TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('One App • One Account • One Ecosystem'),
          ],
        ),
      ),
    );
  }
}