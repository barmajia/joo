import 'package:flutter/material.dart';
import './widgets/drawer.dart';

class Homepapge extends StatefulWidget {
  const Homepapge({super.key});

  @override
  State<Homepapge> createState() => _HomepapgeState();
}

class _HomepapgeState extends State<Homepapge> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: FixidDrawer(),
      appBar: AppBar(
        title: Text('A U R O R A '),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(Icons.menu),
            );
          },
        ),
      ),
      body: Scaffold(body: Column()),
    );
  }
}
