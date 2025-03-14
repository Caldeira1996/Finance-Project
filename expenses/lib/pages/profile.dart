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

  void _deleteImage() {
    setState(() {
      _image = null; // remmove a imagem
    });
    _saveProfile(); // atualiza o banco de dados para remover o caminho da imagem
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Perfil salvo com sucesso!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple, // cor de fundo do Appbar
        elevation: 10,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Padding(
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
                    backgroundColor: Colors.grey[200], // cor dde fundo
                    foregroundColor: Colors.blue,
                    child:
                        _image == null
                            ? Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey[600],
                            )
                            : null,
                  ),
                ),

                if (_image != null) ...[
                  SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _deleteImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            minimumSize: Size(0, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 5,
                            shadowColor: Colors.redAccent,
                          ),
                          icon: Icon(Icons.delete, size: 20),
                          label: Text('Excluir Foto'),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    labelStyle: TextStyle(color: Colors.purple),
                    prefixIcon: Icon(Icons.person, color: Colors.purple),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  style: TextStyle(fontSize: 18),
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
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: Colors.purple,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 18),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua idade';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    prefixIcon: Icon(Icons.edit, color: Colors.purple),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  maxLines: 3,
                  style: TextStyle(fontSize: 18),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple, // cor de fundo
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    shadowColor: Colors.purpleAccent,
                  ),
                  child: Text(
                    'Salvar Perfil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
