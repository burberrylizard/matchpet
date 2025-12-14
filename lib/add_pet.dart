import 'dart:typed_data'; // Required for Web Image Bytes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart'; 

const Color brandPurple = Color(0xFF6A1B9A);

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  // --- Text Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController breedController = TextEditingController(); // <--- NEW
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController(); // <--- NEW
  final TextEditingController colorController = TextEditingController(); // <--- NEW
  final TextEditingController feeController = TextEditingController(); 
  final TextEditingController descriptionController = TextEditingController();

  // --- Dropdown Values ---
  String? _selectedGender; // <--- NEW
  String? _selectedSize;   // <--- NEW

  // --- Checklist State Variables ---
  bool isNeutered = false;
  bool isVaccinated = false;
  bool isPottyTrained = false;
  bool isFriendly = false;

  // --- Image State Variables ---
  Uint8List? _webImage; 
  String? _fileName;
  bool isUploading = false;

  final List<String> genderOptions = ['Male', 'Female', 'Unknown'];
  final List<String> sizeOptions = ['Small', 'Medium', 'Large', 'X-Large'];

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    breedController.dispose();
    ageController.dispose();
    weightController.dispose();
    colorController.dispose();
    feeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------
  // 1. FUNCTION TO PICK IMAGE 
  // ---------------------------------------------------
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      var f = await image.readAsBytes();
      setState(() {
        _webImage = f;
        _fileName = image.name; 
      });
    }
  }

  // ---------------------------------------------------
  // 2. FUNCTION TO UPLOAD TO FIREBASE 
  // ---------------------------------------------------
  Future<String?> _uploadImage() async {
    if (_webImage == null) return null;

    try {
      String uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      final ref = FirebaseStorage.instance
          .ref()
          .child('pet_images')
          .child(uniqueName);

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(_webImage!, metadata);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading: $e");
      return null;
    }
  }

  // ---------------------------------------------------
  // 3. MAIN SUBMIT LOGIC (UPDATED)
  // ---------------------------------------------------
  Future<void> _submitPost() async {
    if (_webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first!")),
      );
      return;
    }

    if (_selectedGender == null || _selectedSize == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Gender and Size.")),
      );
      return;
    }

    setState(() => isUploading = true);

    String? imageUrl = await _uploadImage();

    if (imageUrl != null) {
      try {
        await FirebaseFirestore.instance.collection('pets').add({
          // Basic Info
          'name': nameController.text,
          'type': typeController.text,
          'breed': breedController.text, // <--- SAVED
          'gender': _selectedGender,     // <--- SAVED
          'size': _selectedSize,         // <--- SAVED
          
          // Physical Details
          'age': ageController.text,
          'weight': weightController.text, // <--- SAVED
          'color': colorController.text,   // <--- SAVED
          
          // Admin / Status
          'adoptionFee': feeController.text, 
          'description': descriptionController.text,
          'imageUrl': imageUrl,
          
          // Checklist
          'isNeutered': isNeutered,
          'isVaccinated': isVaccinated,
          'isPottyTrained': isPottyTrained,
          'isFriendly': isFriendly,
          
          // System Data
          'ownerId': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pet posted successfully!")),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        }
      } catch (e) {
        if (mounted) {
           setState(() => isUploading = false);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error saving pet: $e")),
           );
        }
      }
    } else {
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Error uploading image")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Post a Pet for Adoption",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 20),

          // --- PHOTO UPLOAD ---
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.grey.shade400, style: BorderStyle.solid),
              ),
              child: _webImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        _webImage!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                        const SizedBox(height: 10),
                        Text("Tap to upload pet photo",
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 25),

          // --- SECTION 1: IDENTITY ---
          _buildLabel("Pet Name"),
          _buildTextField(controller: nameController, hint: "e.g. Bella"),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Type"),
                    _buildTextField(controller: typeController, hint: "Dog, Cat..."),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Breed"),
                    _buildTextField(controller: breedController, hint: "Labrador, Persian..."),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Gender"),
                    _buildDropdown(
                      value: _selectedGender,
                      items: genderOptions,
                      onChanged: (val) => setState(() => _selectedGender = val),
                      hint: "Select",
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Size"),
                     _buildDropdown(
                      value: _selectedSize,
                      items: sizeOptions,
                      onChanged: (val) => setState(() => _selectedSize = val),
                      hint: "Select",
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // --- SECTION 2: PHYSICAL DETAILS ---
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Age"),
                    _buildTextField(controller: ageController, hint: "e.g. 2 years"),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Weight (kg/lbs)"),
                    _buildTextField(controller: weightController, hint: "e.g. 5kg"),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          _buildLabel("Color / Markings"),
          _buildTextField(controller: colorController, hint: "e.g. Brown with white spots"),

          const SizedBox(height: 15),

          _buildLabel("Adoption Fee (PHP)"),
          _buildTextField(controller: feeController, hint: "e.g. 500 or Free"),

          const SizedBox(height: 20),

          // --- SECTION 3: CHECKLIST ---
          const Text(
            "Health & Status",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildCheckbox("Spayed / Neutered", isNeutered, (val) {
                  setState(() => isNeutered = val!);
                }),
                const Divider(height: 1),
                _buildCheckbox("Vaccinated", isVaccinated, (val) {
                  setState(() => isVaccinated = val!);
                }),
                const Divider(height: 1),
                _buildCheckbox("Potty Trained", isPottyTrained, (val) {
                  setState(() => isPottyTrained = val!);
                }),
                const Divider(height: 1),
                _buildCheckbox("Good with Kids/Pets", isFriendly, (val) {
                  setState(() => isFriendly = val!);
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildLabel("Description"),
          _buildTextField(
              controller: descriptionController,
              hint: "Tell us about the pet's personality...", maxLines: 4),

          const SizedBox(height: 30),

          // --- SUBMIT BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isUploading ? null : _submitPost, 
              style: ElevatedButton.styleFrom(
                backgroundColor: brandPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 2,
              ),
              child: isUploading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "POST PET",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildCheckbox(
      String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      value: value,
      onChanged: onChanged,
      activeColor: brandPurple,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 5),
      child: Text(
        text,
        style:
            const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: brandPurple),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value, 
    required List<String> items, 
    required Function(String?) onChanged,
    required String hint
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}