import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/postannoncement_controller.dart';

class PostannoncementView extends GetView<PostannoncementController> {
  const PostannoncementView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PostannoncementView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'PostannoncementView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
