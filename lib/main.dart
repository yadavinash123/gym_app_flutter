import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/storage/json_store.dart';
import 'features/profile/profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<JsonStore> _store = _open();
  Future<JsonStore> _open() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/fitforge');
    await directory.create(recursive: true);
    return JsonStore(directory);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<JsonStore>(
    future: _store,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return ProviderScope(
          overrides: [storeProvider.overrideWithValue(snapshot.data!)],
          child: const FitForgeApp(),
        );
      }
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Phone storage is unavailable.'),
                      TextButton(
                        onPressed: () => setState(() => _store = _open()),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
