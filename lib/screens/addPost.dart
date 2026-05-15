import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; //
import '../api/pantry.api.dart';
import '../models/FoodItem.model.dart';

class PostItemPage extends StatefulWidget {
  const PostItemPage({super.key});
  @override
  State<PostItemPage> createState() => _PostItemPageState();
}

class _PostItemPageState extends State<PostItemPage> {
  final nameController = TextEditingController();
  final qtyController = TextEditingController();
  DateTime? _selectedDate;
  File? _image;

  // Capture photo via camera
  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) setState(() => _image = File(image.path));
  }

  // Select Expiration Date
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Surplus Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null) Image.file(_image!, height: 150),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Required Photo"),
            ),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name")),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
            ListTile(
              title: Text(_selectedDate == null ? "Select Expiration Date" : "Expires: ${_selectedDate.toString().split(' ')[0]}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && _image != null && _selectedDate != null) {
                   final newItem = FoodItem(
                    name: nameController.text,
                    quantity: int.parse(qtyController.text),
                    expirationDate: _selectedDate!,
                    imageUrl: "placeholder", // [TODO] Upload to Storage later
                  );
                  await FirebasePantryAPI().addFoodItem(newItem.toJson());
                  Navigator.pop(context);
                }
              },
              child: const Text("Post to Pantry"),
            )
          ],
        ),
      ),
    );
  }
}