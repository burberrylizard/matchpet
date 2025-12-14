// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart'; // Import so we can redirect to signup on logout

const Color brandPurple = Color(0xFF6A1B9A);

// ==========================================
// MAIN PROFILE PAGE
// ==========================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignupPage()), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text("Please log in"));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. HEADER SECTION
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox(height: 200, child: Center(child: Text("User data not found")));
              }

              Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
              String fullName = data['fullName'] ?? 'No Name';
              String username = data['username'] ?? 'No Username';
              String email = data['email'] ?? currentUser!.email!;

              return Container(
                padding: const EdgeInsets.only(top: 20, bottom: 30),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: const NetworkImage("https://i.pravatar.cc/300"), 
                    ),
                    const SizedBox(height: 15),
                    Text(
                      fullName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 5),
                    Text("@$username", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                     const SizedBox(height: 5),
                    Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),

          // 2. MENU OPTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Navigates to My Listed Pets Page
                _buildProfileOption(
                  Icons.pets, 
                  "My Listed Pets", 
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListedPetsPage()));
                  }
                ),
                
                // Navigates to Adoption History Page
                _buildProfileOption(
                  Icons.history, 
                  "Adoption History",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdoptionHistoryPage()));
                  }
                ),
                
                const SizedBox(height: 20),
                
                // Logout
                _buildProfileOption(Icons.logout, "Log Out", isRed: true, onTap: _signOut),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {bool isRed = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 1, blurRadius: 5),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRed ? Colors.red.withOpacity(0.1) : brandPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isRed ? Colors.red : brandPurple),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: isRed ? Colors.red : Colors.black87),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap ?? () {},
      ),
    );
  }
}

// ==========================================
// NEW PAGE: MY LISTED PETS
// ==========================================
class MyListedPetsPage extends StatelessWidget {
  const MyListedPetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Listed Pets", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query: Pets where 'ownerId' matches current user
        stream: FirebaseFirestore.instance
            .collection('pets')
            .where('ownerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("You haven't listed any pets yet."),
                ],
              ),
            );
          }

          final pets = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              var pet = pets[index].data() as Map<String, dynamic>;
              String docId = pets[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      pet['imageUrl'] ?? 'https://via.placeholder.com/100',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(pet['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${pet['type']} • ${pet['age']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      // Confirm Deletion
                      bool confirm = await showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("Delete Listing?"),
                          content: const Text("This action cannot be undone."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm) {
                        await FirebaseFirestore.instance.collection('pets').doc(docId).delete();
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// NEW PAGE: ADOPTION HISTORY
// ==========================================
class AdoptionHistoryPage extends StatelessWidget {
  const AdoptionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Adoption History", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query: Pets where 'adopterId' matches current user
        stream: FirebaseFirestore.instance
            .collection('pets')
            .where('adopterId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("You haven't adopted any pets yet."),
                ],
              ),
            );
          }

          final pets = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              var pet = pets[index].data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                      child: Image.network(
                        pet['imageUrl'] ?? 'https://via.placeholder.com/100',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(pet['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Status: Adopted", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}