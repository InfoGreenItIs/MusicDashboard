import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    print('DEBUG: _handleSignIn called');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting signInWithPopup...');
      // Create a Google provider and sign in with popup
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Trigger the authentication flow
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithPopup(googleProvider);

      print(
        'DEBUG: signInWithPopup success. User: ${userCredential.user?.email}',
      );

      final user = userCredential.user;
      if (user != null && user.email != null) {
        print('DEBUG: Querying Firestore for ${user.email}...');

        final querySnapshot = await FirebaseFirestore.instance
            .collection('dashboard_users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        print(
          'DEBUG: Firestore query done. Docs found: ${querySnapshot.docs.length}',
        );

        if (querySnapshot.docs.isNotEmpty) {
          print('DEBUG: User allowed. Calling onLoginSuccess.');
          widget.onLoginSuccess();
        } else {
          print('DEBUG: User not in allow list.');
          await FirebaseAuth.instance.signOut();
          setState(() {
            _errorMessage = 'Access Denied: ${user.email} is not authorized.';
          });
        }
      } else {
        print('DEBUG: User is null or has no email.');
      }
    } catch (error) {
      print('DEBUG: Error caught: $error');
      setState(() {
        _errorMessage = 'Sign in failed. Error: $error';
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
                  Icon(
                    Icons.music_note_rounded,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access the dashboard',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 48),

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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Sign in with Google',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
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
