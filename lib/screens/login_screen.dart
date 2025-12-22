import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // No explicit client ID needed here for Firebase Auth (handled in firebase config)

  bool _isLoading = false;
  String? _errorMessage;

  // Removed hardcoded list in favor of Firestore
  // final List<String> _allowedEmails = [...];

  Future<void> _handleSignIn() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web: Use signInWithPopup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else {
        // Native (macOS/Android/iOS): Use GoogleSignIn package
        final GoogleSignIn googleSignIn = GoogleSignIn();

        // Ensure we force account selection if possible (GoogleSignIn doesn't have direct 'prompt' param like web provider,
        // but signIn() usually prompts if not silently signed in)
        // To force explicit sign in, we can signOut first if needed, but let's try standard flow.
        try {
          await googleSignIn.signOut(); // Force fresh login choice
        } catch (e) {
          // ignore
        }

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          // User canceled
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      if (!mounted) return;

      final user = userCredential.user;
      if (user != null && user.email != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('dashboard_users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (!mounted) return;

        if (querySnapshot.docs.isNotEmpty) {
          widget.onLoginSuccess();
        } else {
          // If access denied, sign out immediately
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() {
              _errorMessage = 'Access Denied: ${user.email} is not authorized.';
            });
          }
        }
      }
    } catch (error) {
      if (!mounted) return;

      String message = 'Sign in failed. Error: $error';

      // Check for Firestore permission denied error
      if (error.toString().contains('permission-denied') ||
          error.toString().contains('missing or insufficient permissions')) {
        message =
            'Access Denied: You are not authorized to access this dashboard.';
        // Ensure we sign out if the permission check failed so they can try again
        await FirebaseAuth.instance.signOut();
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: _buildAmbientBlob(const Color(0xFF6C63FF)),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildAmbientBlob(const Color(0xFF00D1FF)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Login Card
          Center(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Music Dashboard',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[300],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Access restricted to authorized users only',
                            style: TextStyle(
                              color: Colors.blue[200],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[300],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[200],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (kDebugMode && !kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextButton.icon(
                        onPressed: widget.onLoginSuccess,
                        icon: const Icon(
                          Icons.bug_report,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          'Debug: Bypass Login',
                          style: TextStyle(color: Colors.orange),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                  _buildGoogleButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Official Google Logo from CDN
                  Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to simple "G" if image fails to load
                      return Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Sign in with Google',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: const Color(0xFF3C4043),
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAmbientBlob(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
    );
  }
}
