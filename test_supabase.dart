import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  try {
    final response = await Supabase.instance.client
        .from('jobs')
        .insert({
          'category': 'recommended',
          'company': 'Test Company',
          'role': 'Test Role',
          'location': 'Test Location',
          'salary': '1000',
          'deadline': 'Tomorrow',
          'job_type': 'Internship',
          'type_color': 4280391411,
          'icon_code_point': 58318,
          'icon_color': 4279060479,
          'is_starred': false,
        })
        .select()
        .single();
    print('Job added: $response');
  } catch (e) {
    print('Error: $e');
  }
}
