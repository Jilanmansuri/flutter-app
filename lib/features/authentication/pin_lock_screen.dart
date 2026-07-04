import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  final List<int> _pinDigits = [];
  final int _pinLength = 4;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // Auto-prompt biometrics if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateBiometrics();
    });
  }

  Future<void> _authenticateBiometrics() async {
    final user = ref.read(authNotifierProvider);
    if (user != null && user.isBiometricEnabled) {
      final success = await ref.read(biometricServiceProvider).authenticate();
      if (success && mounted) {
        context.go('/dashboard');
      }
    }
  }

  void _onKeyPress(int number) {
    if (_pinDigits.length < _pinLength) {
      setState(() {
        _isError = false;
        _pinDigits.add(number);
      });

      if (_pinDigits.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pinDigits.isNotEmpty) {
      setState(() {
        _isError = false;
        _pinDigits.removeLast();
      });
    }
  }

  void _verifyPin() {
    final enteredPin = _pinDigits.join();
    final verified = ref.read(biometricServiceProvider).verifyPin(enteredPin);
    
    if (verified) {
      context.go('/dashboard');
    } else {
      setState(() {
        _isError = true;
        _pinDigits.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo / Lock Icon
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter Secure PIN',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confirm your identity to unlock.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) {
                final hasDigit = index < _pinDigits.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isError 
                        ? Colors.red 
                        : (hasDigit ? primaryColor : Colors.grey.withValues(alpha: 0.3)),
                  ),
                );
              }),
            ),

            // Keypad Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeypadButton(1),
                      _buildKeypadButton(2),
                      _buildKeypadButton(3),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeypadButton(4),
                      _buildKeypadButton(5),
                      _buildKeypadButton(6),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeypadButton(7),
                      _buildKeypadButton(8),
                      _buildKeypadButton(9),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Biometric Prompt Button
                      IconButton(
                        icon: const Icon(Icons.fingerprint_rounded, size: 36),
                        onPressed: _authenticateBiometrics,
                      ),
                      _buildKeypadButton(0),
                      // Backspace Button
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, size: 28),
                        onPressed: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(int val) {
    return InkWell(
      onTap: () => _onKeyPress(val),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            val.toString(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
