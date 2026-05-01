import 'package:flutter/material.dart';

class ClubMembersScreen extends StatelessWidget {
  const ClubMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Club Members')),
      body: const Center(
        child: Text('Public Club Members Directory Coming Soon!'),
      ),
    );
  }
}
