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
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // প্ল্যান অনুযায়ী: Check → Session Found ? Home : Google Login
    await Future.delayed(const Duration(seconds: 2)); // Splash duration
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌟 ENJOY',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}