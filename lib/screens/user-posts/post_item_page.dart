import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elbeats/api/pantry.api.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class PostItemPage extends StatefulWidget {
  final String postType;
  const PostItemPage({super.key, required this.postType});

  @override
  State<PostItemPage> createState() => _PostItemPageState();
}

class _PostItemPageState extends State<PostItemPage> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  final _picker = ImagePicker();

  // Form Fields State
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedShelfLife;
  String? _selectedCategory;
  String? _preferredSetup = 'Meetup'; // Default value

  // Dietary Tags State
  final List<String> _dietaryOptions = [
    'Vegan',
    'Halal',
    'Vegetarian',
    'Gluten-Free',
    'Dairy-Free',
  ];
  final Set<String> _selectedDietaryTags = {};

  final List<String> _shelfLifeOptions = [
    'Freshly Cooked',
    'Fresh Produce',
    'Sealed / Shelf-stable',
    'Near Expiry',
  ];
  final List<String> _categories = [
    'Fruits & Vegetables',
    'Cooked Meals',
    'Baked Goods',
    'Canned & Pantry',
    'Dairy & Eggs',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();

      print("Image size in bytes: ${imageBytes.length}");

      String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      debugPrint("Base64 conversion failed: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPantry = widget.postType == 'PANTRY';

    return Scaffold(
      // Changes header automatically
      appBar: AppBar(title: Text(isPantry ? "Share Food" : "Request Food")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Image Picker Box
              GestureDetector(
                onTap: _showImageSourceOptions,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Add item photo",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Please enter an item name"
                    : null,
              ),
              const SizedBox(height: 16),

              // Shelf Life / State
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Shelf Life / State",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                items: _shelfLifeOptions
                    .map(
                      (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedShelfLife = val),
                validator: (value) =>
                    value == null ? "Please select shelf life status" : null,
              ),
              const SizedBox(height: 16),

              // Main Category
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Main Category",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (value) =>
                    value == null ? "Please select a category" : null,
              ),
              const SizedBox(height: 24),

              // Dietary Tags
              Text(
                "Dietary Properties",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _dietaryOptions.map((tag) {
                  final isSelected = _selectedDietaryTags.contains(tag);
                  return FilterChip(
                    showCheckmark: false,
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? _selectedDietaryTags.add(tag)
                            : _selectedDietaryTags.remove(tag);
                      });
                    },
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText:
                      "Add details (e.g., ingredients, where you got it, allergen warnings, or exact expiration time)...",
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Please add a description"
                    : null,
              ),
              const SizedBox(height: 24),

              // Preferred Setup
              Text(
                "Preferred Setup",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _preferredSetup == "Meetup"
                            ? colorScheme.primaryContainer
                            : Colors.transparent,
                        side: BorderSide(
                          color: _preferredSetup == "Meetup"
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _preferredSetup = "Meetup"),
                      icon: Icon(
                        Icons.people_alt_outlined,
                        color: _preferredSetup == "Meetup"
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      label: Text(
                        "Meetup",
                        style: TextStyle(
                          color: _preferredSetup == "Meetup"
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _preferredSetup == "Delivery"
                            ? colorScheme.primaryContainer
                            : Colors.transparent,
                        side: BorderSide(
                          color: _preferredSetup == "Delivery"
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _preferredSetup = "Delivery"),
                      icon: Icon(
                        Icons.local_shipping_outlined,
                        color: _preferredSetup == "Delivery"
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      label: Text(
                        "Delivery",
                        style: TextStyle(
                          color: _preferredSetup == "Delivery"
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        _selectedImage != null) {
                      try {
                        final base64Image = await convertImageToBase64(
                          _selectedImage!,
                        );

                        if (base64Image == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Image conversion failed"),
                            ),
                          );
                          return;
                        }

                        final user = FirebaseAuth.instance.currentUser;

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("You must be logged in to post."),
                            ),
                          );
                          return;
                        }

                        final userDoc = await FirebaseFirestore.instance
                            .collection("users")
                            .doc(user.uid)
                            .get();

                        final ownerName =
                            userDoc.data()?['username'] ?? "Anonymous User";

                        final Map<String, dynamic> newFoodItem = {
                          'postType': widget.postType,
                          'name': _nameController.text.trim(),
                          'description': _descriptionController.text.trim(),
                          'shelfLife': _selectedShelfLife,
                          'category': _selectedCategory,
                          'dietaryTags': _selectedDietaryTags.toList(),
                          'setupMethod': _preferredSetup,
                          'status': 'Available',
                          'createdAt': Timestamp.now(),
                          'imageBase64': base64Image,
                          'ownerId': user.uid,
                          'ownerName': ownerName,
                          'requestedBy': [],
                        };

                        await FirebasePantryAPI().addFoodItem(newFoodItem);

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        debugPrint("Error posting: $e");
                      }
                    }
                  },

                  child: Text(
                    isPantry
                        ? "Post to Community Pantry"
                        : "Submit Food Request",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
