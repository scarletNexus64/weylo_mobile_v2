import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/entrypage_controller.dart';

class EntrypageView extends GetView<EntrypageController> {
  const EntrypageView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EntrypageView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'EntrypageView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
