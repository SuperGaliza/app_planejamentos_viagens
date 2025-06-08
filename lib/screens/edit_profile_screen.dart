import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../utils/session_manager.dart';
import '../JsonModels/users.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final db = DatabaseHelper();
  Users? _currentUser;
  String? _newImagePath;
  bool _isLoading = true;
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final userId = await SessionManager.getLoggedInUserId();
    if (userId != null) {
      final user = await db.getUserById(userId);
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _newImagePath = image.path;
      });
      _saveProfilePicture();
    }
  }

  void _saveProfilePicture() async {
    if (_currentUser == null || _newImagePath == null) return;

    final updatedUser = Users(
      usrId: _currentUser!.usrId,
      usrName: _currentUser!.usrName,
      usrPassword: _currentUser!.usrPassword,
      profileImagePath: _newImagePath,
    );

    await db.updateUser(updatedUser);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Foto de perfil atualizada!'),
          backgroundColor: Colors.green),
    );
  }

  void _changePassword() async {
    if (_passwordFormKey.currentState?.validate() ?? false) {
      final userId = await SessionManager.getLoggedInUserId();
      if (userId == null) return;

      final success = await db.changePassword(
        userId,
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Senha alterada com sucesso!'),
              backgroundColor: Colors.green),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Senha atual incorreta.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImage;
    if (_newImagePath != null) {
      profileImage = FileImage(File(_newImagePath!));
    } else if (_currentUser?.profileImagePath != null &&
        _currentUser!.profileImagePath!.isNotEmpty) {
      profileImage = FileImage(File(_currentUser!.profileImagePath!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('Foto de Perfil',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Escolher da Galeria'),
                    onPressed: _pickImage,
                  ),
                  const Divider(height: 40),
                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alterar Senha',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: !_isCurrentPasswordVisible,
                          decoration: _buildInputDecoration(
                              'Senha Atual',
                              Icons.lock_outline,
                              _isCurrentPasswordVisible,
                              () => setState(() => _isCurrentPasswordVisible =
                                  !_isCurrentPasswordVisible)),
                          validator: (value) =>
                              value!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_isNewPasswordVisible,
                          decoration: _buildInputDecoration(
                              'Nova Senha',
                              Icons.lock,
                              _isNewPasswordVisible,
                              () => setState(() => _isNewPasswordVisible =
                                  !_isNewPasswordVisible)),
                          validator: (value) {
                            if (value!.isEmpty) return 'Campo obrigatório';
                            // if (value.length < 6) return 'Mínimo de 6 caracteres'; // LINHA REMOVIDA
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: _buildInputDecoration(
                              'Confirmar Nova Senha',
                              Icons.lock_person_sharp,
                              _isConfirmPasswordVisible,
                              () => setState(() => _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible)),
                          validator: (value) {
                            if (value!.isEmpty) return 'Campo obrigatório';
                            if (value != _newPasswordController.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4DB6AC),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Alterar Senha',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData prefixIcon,
      bool isVisible, VoidCallback toggleVisibility) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      suffixIcon: IconButton(
        icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
        onPressed: toggleVisibility,
      ),
    );
  }
}