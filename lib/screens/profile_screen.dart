import 'dart:io';
import 'package:flutter/material.dart';
import '../Authentication/login_screen.dart';
import '../JsonModels/users.dart';
import '../database/database_helper.dart';
import '../utils/session_manager.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final db = DatabaseHelper();
  Users? _currentUser;
  int _pastTripsCount = 0;
  int _futureTripsCount = 0;
  bool _isLoading = true;
  

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final userId = await SessionManager.getLoggedInUserId();
    if (userId != null) {
      final results = await Future.wait([
        db.getUserById(userId),
        db.countPastTrips(userId),
        db.countFutureTrips(userId),
      ]);
      if (mounted) {
        setState(() {
          _currentUser = results[0] as Users?;
          _pastTripsCount = results[1] as int;
          _futureTripsCount = results[2] as int;
          _isLoading = false;
        });
      }
    } else {
      _logout();
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color profileThemeColor = Color(0xFF4DB6AC);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(profileThemeColor),
                    _buildUserInfoSection(),
                    const SizedBox(height: 20),
                    _buildStatsCard(),
                    const SizedBox(height: 20),
                    _buildOptionsMenu(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Meu Perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final userName = _currentUser?.usrName ?? 'Usuário';
    final imagePath = _currentUser?.profileImagePath;

    ImageProvider? profileImage;
    if (imagePath != null && imagePath.isNotEmpty) {
      profileImage = FileImage(File(imagePath));
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: profileImage,
          child: profileImage == null
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 48, color: Colors.white),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          userName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Viagens Realizadas', _pastTripsCount.toString()),
              _buildStatItem('Próximas Viagens', _futureTripsCount.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildOptionsMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          _buildMenuTile(
            title: 'Editar Perfil',
            icon: Icons.person_outline,
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
              if (result == true) {
                _loadProfileData();
              }
            },
          ),
          const Divider(),
          _buildMenuTile(
            title: 'Sair',
            icon: Icons.logout,
            color: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey.shade800),
      title: Text(title,
          style: TextStyle(
              color: color ?? Colors.grey.shade800,
              fontWeight: FontWeight.w600)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}