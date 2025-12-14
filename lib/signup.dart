import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart'; // Make sure this import points to your dashboard file

// Define the brand color locally to ensure it matches
const Color brandPurple = Color(0xFF6A1B9A);

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Controllers for all fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = "";
  bool isError = false;
  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleSignUp() async {
    // 1. Reset State
    setState(() {
      isError = false;
      errorMessage = "";
    });

    // 2. Simple Validation
    if (fullNameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        isError = true;
        errorMessage = "All fields are required.";
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      // 3. Create User in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 4. Save Extra Data (Name, Username) to Firestore
      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullNameController.text.trim(),
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => isLoading = false);
        // 5. Navigate to Dashboard on Success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isError = true;
          errorMessage = e.message ?? "Signup failed. Please try again.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isError = true;
          errorMessage = "An unexpected error occurred.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Header Section
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ignore: deprecated_member_use
                    color: brandPurple.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    size: 50,
                    color: brandPurple,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Join our community of pet lovers',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // 2. Input Fields

                // FULL NAME
                _buildTextField(
                  controller: fullNameController,
                  hint: "Full Name",
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 15),

                // USERNAME
                _buildTextField(
                  controller: usernameController,
                  hint: "Username",
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 15),

                // EMAIL
                _buildTextField(
                  controller: emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                // PASSWORD
                _buildTextField(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                // 3. Error Message
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isError ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 20),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 4. Action Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(55),
                    backgroundColor: brandPurple,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: isLoading ? null : handleSignUp,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SIGN UP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // 5. Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back to Login
                      },
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: brandPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to keep code clean
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: brandPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}