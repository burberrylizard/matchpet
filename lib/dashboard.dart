// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petmatch/add_pet.dart';
import 'package:petmatch/profile.dart';
import 'package:petmatch/chat.dart'; 

const Color brandPurple = Color(0xFF6A1B9A);

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  
  // --- SEARCH STATE ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),        // 0. Home
      const FavoritesPage(),      // 1. Favorites
      const AddPetPage(),         // 2. Add Pet
      const ChatPage(),           // 3. Chat 
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), 
              activeIcon: Icon(Icons.home), 
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), 
              activeIcon: Icon(Icons.favorite), 
              label: 'Favorites'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), 
              activeIcon: Icon(Icons.add_circle), 
              label: 'Add Pet'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), 
              activeIcon: Icon(Icons.chat_bubble), 
              label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), 
              activeIcon: Icon(Icons.person), 
              label: 'Profile'),
        ],
      ),
    );
  }

  // ------------------------------------
  // HOME PAGE CONTENT (Updated)
  // ------------------------------------
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HERO SECTION WITH SEARCH
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
                        shadows: [
                          Shadow(offset: Offset(0, 2), blurRadius: 3.0, color: Colors.black45)
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- FUNCTIONAL SEARCH BAR ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase().trim();
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search by name or type...',
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

          const SizedBox(height: 25),

          // 2. TITLE FOR GRID
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Recently Added",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 15),

          // 3. LIVE GRID (StreamBuilder + Filter Logic)
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

                final uid = FirebaseAuth.instance.currentUser?.uid;
                
                // --- FILTERING LOGIC ---
                final pets = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // 1. Basic Filters (Hide own posts & adopted)
                  bool isNotOwner = data['ownerId'] != uid;
                  bool isAvailable = data['status'] != 'Adopted';

                  // 2. Search Filter (Name or Type)
                  bool matchesSearch = true;
                  if (_searchQuery.isNotEmpty) {
                    String name = (data['name'] ?? '').toString().toLowerCase();
                    String type = (data['type'] ?? '').toString().toLowerCase();
                    matchesSearch = name.contains(_searchQuery) || type.contains(_searchQuery);
                  }

                  return isNotOwner && isAvailable && matchesSearch; 
                }).toList();

                if (pets.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No pets found matching your search."),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.70, 
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

  // Helper: Pet Card
  Widget _buildPetCard(BuildContext context, Map<String, dynamic> pet, String petId) {
    bool isPending = pet['status'] == 'Pending';

    return GestureDetector(
      onTap: () {
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
            
            // Pending Badge
            if (isPending)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "PENDING",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

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
}

// ==========================================
// WIDGET: FAVORITE BUTTON
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
              await favRef.delete();
            } else {
              Map<String, dynamic> dataToSave = Map.from(petData);
              dataToSave['addedAt'] = FieldValue.serverTimestamp();
              await favRef.set(dataToSave);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
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
// PAGE: PET DETAILS PAGE (Stateful with Status)
// ==========================================
class PetDetailsPage extends StatefulWidget {
  final Map<String, dynamic> petData;
  final String petId;

  const PetDetailsPage({super.key, required this.petData, required this.petId});

  @override
  State<PetDetailsPage> createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends State<PetDetailsPage> {
  late String currentStatus;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.petData['status'] ?? 'Available';
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .update({'status': newStatus});
      
      setState(() {
        currentStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to $newStatus")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update status")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isOwner = currentUser != null && widget.petData['ownerId'] == currentUser.uid;

    Color statusColor;
    if (currentStatus == 'Adopted') {
      statusColor = Colors.red;
    } else if (currentStatus == 'Pending') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                backgroundColor: brandPurple,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    widget.petData['imageUrl'] ?? 'https://via.placeholder.com/300',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- OWNER STATUS CONTROLS ---
                      if (isOwner) 
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Set Status:", style: TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                value: currentStatus,
                                underline: const SizedBox(),
                                items: ['Available', 'Pending', 'Adopted'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value, 
                                      style: TextStyle(
                                        color: value == 'Adopted' ? Colors.red : 
                                               value == 'Pending' ? Colors.orange : Colors.green,
                                        fontWeight: FontWeight.bold
                                      )
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) _updateStatus(val);
                                },
                              ),
                            ],
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.petData['name'] ?? 'Unknown',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "${widget.petData['breed'] ?? 'Mixed'} • ${widget.petData['age']}",
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          
                          // --- STATUS BADGE (For Visitors) ---
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.petData['adoptionFee'] != null && widget.petData['adoptionFee'].toString().isNotEmpty
                                    ? "PHP ${widget.petData['adoptionFee']}"
                                    : "Free",
                                style: const TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold, 
                                  color: brandPurple
                                ),
                              ),
                              if (!isOwner && currentStatus != 'Available')
                                Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Text(
                                    currentStatus.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                )
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 25),

                      // --- DETAILS GRID ---
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildDetailChip(Icons.transgender, widget.petData['gender'] ?? 'Unknown'),
                          _buildDetailChip(Icons.straighten, widget.petData['size'] ?? 'Unknown'),
                          _buildDetailChip(Icons.monitor_weight_outlined, widget.petData['weight'] ?? '-'),
                          _buildDetailChip(Icons.palette_outlined, widget.petData['color'] ?? 'Unknown'),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // --- CHECKLIST ---
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (widget.petData['isNeutered'] == true) _buildChip("Neutered", Colors.blue),
                          if (widget.petData['isVaccinated'] == true) _buildChip("Vaccinated", Colors.green),
                          if (widget.petData['isPottyTrained'] == true) _buildChip("Potty Trained", Colors.orange),
                          if (widget.petData['isFriendly'] == true) _buildChip("Friendly", Colors.pink),
                        ],
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "About Me",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.petData['description'] ?? "No description provided.",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                      ),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- ADOPT BUTTON LOGIC ---
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: isOwner
                ? _buildDisabledButton("You posted this pet")
                : currentStatus == 'Adopted'
                  ? _buildDisabledButton("Adopted")
                  : currentStatus == 'Pending'
                    ? _buildDisabledButton("Adoption Pending")
                    : ElevatedButton(
                        onPressed: () async {
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please log in to adopt.")),
                            );
                            return;
                          }
                          
                          String ownerId = widget.petData['ownerId'];
                          List<String> ids = [currentUser.uid, ownerId];
                          ids.sort(); 
                          String chatId = "${ids[0]}_${ids[1]}_${widget.petId}"; 

                          final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();

                          if (!chatDoc.exists) {
                            await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
                              'participants': [currentUser.uid, ownerId],
                              'participantNames': [currentUser.email, "Owner"], 
                              'petName': widget.petData['name'],
                              'petId': widget.petId,
                              'lastMessage': 'Started an inquiry for ${widget.petData['name']}',
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            
                            await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
                              'text': "Hi! I'm interested in adopting ${widget.petData['name']}.",
                              'senderId': currentUser.uid,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          }

                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) => ChatRoomPage(chatId: chatId, otherUserName: "Owner of ${widget.petData['name']}")
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("ADOPT ME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
          ),
          
          Positioned(
            top: 40,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: FavoriteButton(petData: widget.petData, petId: widget.petId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
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

  Widget _buildDetailChip(IconData icon, String label) {
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

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