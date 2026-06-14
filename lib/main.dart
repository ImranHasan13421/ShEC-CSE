//lib/main.dart/
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ShEC_CSE/features/auth/screens/splash_screen.dart';
import 'package:ShEC_CSE/features/auth/screens/set_new_password_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';

import 'package:ShEC_CSE/core/services/theme_service.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/core/utils/subject_information.dart';

// Import Feature BLoCs
import 'package:ShEC_CSE/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ShEC_CSE/features/auth/presentation/bloc/auth_event.dart';
import 'package:ShEC_CSE/features/notices/presentation/bloc/notice_bloc.dart';
import 'package:ShEC_CSE/features/notices/presentation/bloc/notice_event.dart';
import 'package:ShEC_CSE/features/results/presentation/bloc/result_bloc.dart';
import 'package:ShEC_CSE/features/results/presentation/bloc/result_event.dart';
import 'package:ShEC_CSE/features/messenger/presentation/bloc/chat_bloc.dart';
import 'package:ShEC_CSE/features/messenger/presentation/bloc/chat_event.dart';
import 'package:ShEC_CSE/features/accounting/presentation/bloc/accounting_bloc.dart';
import 'package:ShEC_CSE/features/gallery/presentation/bloc/gallery_bloc.dart';
import 'package:ShEC_CSE/features/gallery/presentation/bloc/gallery_event.dart';
import 'package:ShEC_CSE/features/alumni/presentation/bloc/alumni_bloc.dart';
import 'package:ShEC_CSE/features/alumni/presentation/bloc/alumni_event.dart';
import 'package:ShEC_CSE/features/contests/presentation/bloc/contest_bloc.dart';
import 'package:ShEC_CSE/features/contests/presentation/bloc/contest_event.dart';
import 'package:ShEC_CSE/features/jobs/presentation/bloc/job_bloc.dart';
import 'package:ShEC_CSE/features/jobs/presentation/bloc/job_event.dart';
import 'package:ShEC_CSE/features/resources/presentation/bloc/resource_bloc.dart';
import 'package:ShEC_CSE/features/resources/presentation/bloc/resource_event.dart';
import 'package:ShEC_CSE/features/department/presentation/bloc/teacher_bloc.dart';
import 'package:ShEC_CSE/features/department/presentation/bloc/teacher_event.dart';
import 'package:ShEC_CSE/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ShEC_CSE/features/profile/presentation/bloc/profile_event.dart';
import 'package:ShEC_CSE/features/about/presentation/bloc/contributor_bloc.dart';
import 'package:ShEC_CSE/features/about/presentation/bloc/contributor_event.dart';

// Import Repositories
import 'package:ShEC_CSE/features/gallery/data/repositories/gallery_repository_impl.dart';
import 'package:ShEC_CSE/features/alumni/data/repositories/alumni_repository_impl.dart';
import 'package:ShEC_CSE/features/contests/data/repositories/contest_repository_impl.dart';
import 'package:ShEC_CSE/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:ShEC_CSE/features/resources/data/repositories/resource_repository_impl.dart';
import 'package:ShEC_CSE/features/department/data/repositories/teacher_repository_impl.dart';
import 'package:ShEC_CSE/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:ShEC_CSE/features/about/data/repositories/contributor_repository_impl.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Subject Information Database
  await SubjectInformation.init();

  // Initialize Theme Service
  await ThemeService.instance.init();
  
  // Initialize Ambient Settings
  await AmbientSettings.init();
  
  // Initialize listener with navigation capability
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    if (event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const SetNewPasswordScreen()),
      );
    }
  });

  AuthService.initializeAuthListener();

  final session = Supabase.instance.client.auth.currentSession;
  final isLoggedIn = session != null;

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider<NoticeBloc>(
          create: (context) => NoticeBloc()..add(const FetchNoticesRequested()),
        ),
        BlocProvider<ResultBloc>(
          create: (context) => ResultBloc()..add(LoadResultsRequested()),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc()..add(FetchRoomsRequested()),
        ),
        BlocProvider<AccountingBloc>(
          create: (context) => AccountingBloc(),
        ),
        BlocProvider<GalleryBloc>(
          create: (context) => GalleryBloc(
            galleryRepository: GalleryRepositoryImpl(),
          )..add(const FetchGalleryItemsRequested()),
        ),
        BlocProvider<AlumniBloc>(
          create: (context) => AlumniBloc(
            alumniRepository: AlumniRepositoryImpl(),
          )..add(const FetchAlumniRequested()),
        ),
        BlocProvider<ContestBloc>(
          create: (context) => ContestBloc(
            contestRepository: ContestRepositoryImpl(),
          )..add(const FetchContestsRequested()),
        ),
        BlocProvider<JobBloc>(
          create: (context) => JobBloc(
            jobRepository: JobRepositoryImpl(),
          )..add(const FetchJobsRequested()),
        ),
        BlocProvider<ResourceBloc>(
          create: (context) => ResourceBloc(
            resourceRepository: ResourceRepositoryImpl(),
          )..add(const FetchResourcesRequested()),
        ),
        BlocProvider<TeacherBloc>(
          create: (context) => TeacherBloc(
            teacherRepository: TeacherRepositoryImpl(),
          )..add(const FetchTeachersRequested()),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(
            profileRepository: ProfileRepositoryImpl(),
          )..add(const FetchProfileRequested()),
        ),
        BlocProvider<ContributorBloc>(
          create: (context) => ContributorBloc(
            ContributorRepositoryImpl(),
          )..add(const FetchContributorsRequested()),
        ),
      ],
      child: ShEcCseApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class ShEcCseApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const ShEcCseApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final themeService = ThemeService.instance;
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'ShEC CSE',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.sdkThemeMode,
          theme: themeService.getThemeData(false),
          darkTheme: themeService.getThemeData(true),
          home: SplashScreen(isLoggedIn: isLoggedIn),
        );
      },
    );
  }
}