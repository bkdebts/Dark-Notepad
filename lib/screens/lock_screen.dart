import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/loading_indicator.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<String> _pin = ['', '', '', ''];
  int _currentPinIndex = 0;
  bool _isLoading = false;
  bool _isError = false;
  String? _errorMessage;
  bool _isBiometricAvailable = false;
  
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        }
      });
    
    // Check if biometric authentication is available
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAvailable = await authService.isBiometricAvailable();
    
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
      });
      
      // Automatically trigger biometric authentication if available
      if (_isBiometricAvailable) {
        _authenticateWithBiometrics();
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isError = false;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final authenticated = await authService.authenticateWithBiometrics();
      
      if (authenticated && mounted) {
        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Biometric authentication failed';
          _isError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _isError = true;
        });
      }
    }
  }

  void _onKeyPressed(String digit) {
    if (_currentPinIndex < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin[_currentPinIndex] = digit;
        _currentPinIndex++;
        _isError = false;
        _errorMessage = null;
      });
      
      // If PIN is complete, verify it
      if (_currentPinIndex == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_currentPinIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentPinIndex--;
        _pin[_currentPinIndex] = '';
        _isError = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    final pin = _pin.join();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isError = false;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final verified = await authService.verifyAppLockPin(pin);
      
      if (verified && mounted) {
        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        // Show error and clear PIN
        _animationController.forward();
        
        setState(() {
          _isLoading = false;
          _errorMessage = 'Incorrect PIN';
          _isError = true;
          _pin.fillRange(0, 4, '');
          _currentPinIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _isError = true;
          _pin.fillRange(0, 4, '');
          _currentPinIndex = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // App logo and title
                Column(
                  children: [
                    const SizedBox(height: 48),
                    
                    // App logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      'App Lock',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      'Enter your PIN to unlock',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // PIN input indicators
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _pin[index].isNotEmpty
                                  ? (_isError
                                      ? AppTheme.errorColor
                                      : AppTheme.primaryColor)
                                  : AppTheme.cardColor,
                              border: Border.all(
                                color: _isError
                                    ? AppTheme.errorColor
                                    : AppTheme.dividerColor,
                                width: 1,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Error message
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                
                // PIN keypad
                Column(
                  children: [
                    // First row (1-3)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        final digit = (index + 1).toString();
                        return _buildKeypadButton(digit);
                      }),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Second row (4-6)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        final digit = (index + 4).toString();
                        return _buildKeypadButton(digit);
                      }),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Third row (7-9)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        final digit = (index + 7).toString();
                        return _buildKeypadButton(digit);
                      }),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fourth row (biometric, 0, delete)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Biometric button (or empty container)
                        _isBiometricAvailable
                            ? _buildBiometricButton()
                            : _buildEmptyButton(),
                        
                        // 0 button
                        _buildKeypadButton('0'),
                        
                        // Delete button
                        _buildDeleteButton(),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : () => _onKeyPressed(digit),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardColor,
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _onDeletePressed,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardColor,
          ),
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 24,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _authenticateWithBiometrics,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardColor,
          ),
          child: _isLoading
              ? const LoadingIndicator(size: 24)
              : const Center(
                  child: Icon(
                    Icons.fingerprint,
                    size: 24,
                    color: AppTheme.primaryColor,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
    );
  }
}
