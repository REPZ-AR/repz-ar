import 'package:flutter/material.dart';

class ClientManagementPage extends StatelessWidget {
  const ClientManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client')),
      body: const Center(child: Text('Client Page')),
    );
  }
}

