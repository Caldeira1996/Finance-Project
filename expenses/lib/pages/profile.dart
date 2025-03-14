import 'package:expenses/bd/bd.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' hide Image;
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:sqflite/sqflite.dart';

class ProfileScreen extends StatefulWidget {
  //const Profile({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Carrega o perfil ao inicializar a tela
  }

  Future<void> _loadProfile() async {
    final userId = 1;
    final dbHelper = DatabaseHelper.instance;
    final profile = await dbHelper.getProfile(userId);

    if (profile != null) {
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _ageController.text = profile['age'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        if (profile['imagePath'] != null) {
          _image = File(profile['imagePath']);
        }
      });
    }
  }

  //Método de carregar perfil
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      //Redimensiona a image para um tamanho máximo e 800x800 px
      final imageFile = File(pickedFile.path);
      final image = decodeImage(await imageFile.readAsBytes());
      if (image != null) {
        final resizeImage = copyResize(image, width: 800, height: 800);
        final resizedFile = File(pickedFile.path)
          ..writeAsBytesSync(encodePng(resizeImage));

        setState(() {
          _image = resizedFile;
        });
      }
    }
  }

  void _openImageFullScreen() {
    if (_image != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(
                  title: Text('Imagem de Perfil'),
                  backgroundColor: Colors.black,
                ),
                body: PhotoView(
                  imageProvider: FileImage(_image!),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  backgroundDecoration: BoxDecoration(color: Colors.black),
                ),
              ),
        ),
      );
    }
  }

  // Método para salvar o perfil no banco de dados
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final userId = 1; // Substitua pelo ID do usuário logado
      final dbHelper = DatabaseHelper.instance;

      // Salva ou atualiza o perfil
      if (_image != null) {
        await dbHelper.saveProfile(
          userId,
          _nameController.text,
          _ageController.text,
          _bioController.text,
          _image!.path, // Salva o caminho da imagem
        );
      } else {
        await dbHelper.saveProfile(
          userId,
          _nameController.text,
          _ageController.text,
          _bioController.text,
          null, // Se não houver imagem, salva null
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Perfil salvo com sucesso!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child:
                      _image == null ? Icon(Icons.camera_alt, size: 50) : null,
                ),
              ),

              if (_image != null)
                TextButton(
                  onPressed: _openImageFullScreen,
                  child: Text('Selecione uma imagem'),
                ),

              SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Idade',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua idaed';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma bio caso deseja';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Salvar Perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
