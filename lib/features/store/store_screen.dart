import 'package:flutter/material.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        backgroundColor: Colors.black87,
      ),
      body: const Center(
        child: Text('Store Coming Soon!'),
      ),
    );
  }
}
