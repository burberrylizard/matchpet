// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petmatch/add_pet.dart';
import 'package:petmatch/profile.dart';

const Color brandPurple = Color(0xFF6A1B9A);

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),        // 0. Home
      const FavoritesPage(),      // 1. Favorites (Now a real page)
      const AddPetPage(),         // 2. Add Pet
      const Center(child: Text("Chat Page")), // 3. Chat
      const ProfilePage(),        // 4. Profile
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'petfinder',
          style: TextStyle(
            color: brandPurple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: brandPurple),
            onPressed: () {},
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: brandPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Add Pet'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ------------------------------------
  // HOME PAGE CONTENT
  // ------------------------------------
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HERO SECTION
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 250,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://placedog.net/800/400?random'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const Text(
                      'Find your New Best Friend',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(offset: Offset(0, 2), blurRadius: 3.0, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search Terrier, Kitten, etc.',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. CATEGORY PILLS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryPill(Icons.pets, "Dogs"),
                _buildCategoryPill(Icons.cruelty_free, "Cats"),
                _buildCategoryPill(Icons.emoji_nature, "Other"),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // 3. TITLE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Recently Added",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 15),

          // 4. LIVE GRID (StreamBuilder)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pets')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No pets posted yet."));
                }

                final pets = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.70, // Slightly taller for the heart button
                  ),
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    var petData = pets[index].data() as Map<String, dynamic>;
                    String petId = pets[index].id;

                    return _buildPetCard(context, petData, petId);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 40), 
        ],
      ),
    );
  }

  // ------------------------------------
  // PET CARD WIDGET
  // ------------------------------------
  Widget _buildPetCard(BuildContext context, Map<String, dynamic> pet, String petId) {
    return GestureDetector(
      onTap: () {
        // Navigate to Details Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailsPage(petData: pet, petId: petId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
            )
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      pet['imageUrl'] ?? 'https://via.placeholder.com/150',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.pets, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                // Text
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${pet['type']} • ${pet['age']}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // HEART BUTTON (Positioned Bottom Right)
            Positioned(
              bottom: 8,
              right: 8,
              child: FavoriteButton(petData: pet, petId: petId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: brandPurple),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ==========================================
// NEW WIDGET: FAVORITE BUTTON (Handles Logic)
// ==========================================
class FavoriteButton extends StatelessWidget {
  final Map<String, dynamic> petData;
  final String petId;

  const FavoriteButton({super.key, required this.petData, required this.petId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      // Listen to this specific pet in the user's favorites
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(petId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        bool isFavorite = snapshot.data!.exists;

        return GestureDetector(
          onTap: () async {
            final favRef = FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('favorites')
                .doc(petId);

            if (isFavorite) {
              // Remove from favorites
              await favRef.delete();
            } else {
              // Add to favorites (Save basic info for the list)
              await favRef.set({
                'name': petData['name'],
                'type': petData['type'],
                'age': petData['age'],
                'imageUrl': petData['imageUrl'],
                'addedAt': FieldValue.serverTimestamp(),
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// NEW PAGE: PET DETAILS PAGE (Expand)
// ==========================================
class PetDetailsPage extends StatelessWidget {
  final Map<String, dynamic> petData;
  final String petId;

  const PetDetailsPage({super.key, required this.petData, required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. App Bar with Image
              SliverAppBar(
                expandedHeight: 350,
                backgroundColor: brandPurple,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    petData['imageUrl'] ?? 'https://via.placeholder.com/300',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 2. Content Body
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0), // Pull up overlap
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                petData['name'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${petData['type']} • ${petData['age']}",
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          Text(
                            petData['adoptionFee'] != null && petData['adoptionFee'].toString().isNotEmpty
                                ? "PHP ${petData['adoptionFee']}"
                                : "Free",
                            style: const TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                              color: brandPurple
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 25),

                      // Checklist Chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (petData['isNeutered'] == true) _buildChip("Neutered", Colors.blue),
                          if (petData['isVaccinated'] == true) _buildChip("Vaccinated", Colors.green),
                          if (petData['isPottyTrained'] == true) _buildChip("Potty Trained", Colors.orange),
                          if (petData['isFriendly'] == true) _buildChip("Friendly", Colors.pink),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Description
                      const Text(
                        "About Me",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        petData['description'] ?? "No description provided.",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                      ),
                      
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. Adopt Button (Floating at bottom)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Add Chat/Adopt logic here
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request sent to owner!")));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("ADOPT ME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          
          // 4. Heart Button (Floating over content)
          Positioned(
            top: 40,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: FavoriteButton(petData: petData, petId: petId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

// ==========================================
// NEW PAGE: FAVORITES PAGE
// ==========================================
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Please log in"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorites", style: TextStyle(color: brandPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .orderBy('addedAt', descending: true)
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
                  Icon(Icons.favorite_border, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("No favorites yet"),
                ],
              ),
            );
          }

          final favs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              var pet = favs[index].data() as Map<String, dynamic>;
              String petId = favs[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  onTap: () {
                    // Navigate to Details using the saved snapshot data
                    // Note: This data might be slightly stale compared to the main 'pets' collection,
                    // but it saves reads. Ideally, you fetch the fresh data here.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetDetailsPage(petData: pet, petId: petId),
                      ),
                    );
                  },
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}