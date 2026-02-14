import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/feeds_controller.dart';

class FeedsView extends GetView<FeedsController> {
  const FeedsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FeedsView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'FeedsView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
