import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/repositories/user_repository.dart';
import 'package:ecommunity/screens/profile/public_profile_screen.dart';
import 'package:flutter/material.dart';

class UserListScreen extends StatefulWidget {
  final String title;
  final List<String> userIds;

  const UserListScreen({super.key, required this.title, required this.userIds});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = true;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (widget.userIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final users = await _userRepository.getUsersByIds(widget.userIds);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text("Nenhum usuário encontrado."))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(user.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PublicProfileScreen(userId: user.id),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
