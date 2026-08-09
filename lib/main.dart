import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'repositories/supabase_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ryzedpbkzspwvrnrppij.supabase.co',
    publishableKey:
        'sb_publishable_LqvRIQopPC2KYbU7pCyIaw_5UatAlPi',
  );

  final SupabaseRepository repository =
      SupabaseRepository(Supabase.instance.client);

  runApp(NestingChampionsApp(repository: repository));
}
