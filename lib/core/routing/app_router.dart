import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/channel/presentation/channel_page.dart';
import '../../features/channel/presentation/create_channel_page.dart';
import '../../features/chat/presentation/chat_list_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/chat/presentation/create_group_page.dart';
import '../../features/chat/presentation/group_info_page.dart';
import '../../features/create/presentation/create_center_page.dart';
import '../../features/creator/presentation/creator_studio_page.dart';
import '../../features/editor/presentation/video_editor_page.dart';
import '../../features/fnf/presentation/fnf_page.dart';
import '../../features/games/presentation/game_creator_page.dart';
import '../../features/games/presentation/game_player_page.dart';
import '../../features/games/presentation/tic_tac_toe_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/learning/presentation/course_detail_page.dart';
import '../../features/learning/presentation/create_course_page.dart';
import '../../features/learning/presentation/learning_page.dart';
import '../../features/learning/presentation/lesson_page.dart';
import '../../features/learning/presentation/quiz_page.dart';
import '../../features/live/presentation/go_live_page.dart';
import '../../features/live/presentation/live_list_page.dart';
import '../../features/live/presentation/live_room_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/profile/presentation/edit_profile_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/shorts/presentation/shorts_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/tv/presentation/tv_page.dart';
import '../../features/videos/presentation/video_player_page.dart';
import '../../features/videos/presentation/video_upload_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/shorts', builder: (_, __) => const ShortsPage()),
          GoRoute(path: '/create', builder: (_, __) => const CreateCenterPage()),
          GoRoute(path: '/fnf', builder: (_, __) => const FnfPage()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        ],
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/create/video',
          builder: (_, __) => const VideoUploadPage(isShort: false)),
      GoRoute(path: '/create/short',
          builder: (_, __) => const VideoUploadPage(isShort: true)),
      GoRoute(path: '/editor', builder: (_, state) {
        final e = state.extra as Map<String, dynamic>;
        return VideoEditorPage(
          cloudUrl: e['url'], publicId: e['public_id'], isShort: e['is_short'],
        );
      }),
      GoRoute(path: '/video/:id', builder: (_, state) =>
          VideoPlayerPage(id: state.pathParameters['id']!)),
      GoRoute(path: '/channel/create', builder: (_, __) => const CreateChannelPage()),
      GoRoute(path: '/channel/:id', builder: (_, state) =>
          ChannelPage(channelId: state.pathParameters['id']!)),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfilePage()),
      GoRoute(path: '/creator-studio', builder: (_, __) => const CreatorStudioPage()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatListPage()),
      GoRoute(path: '/chat/:id', builder: (_, state) {
        final e = (state.extra as Map?) ?? {};
        return ChatPage(
          conversationId: state.pathParameters['id']!,
          title: e['title'] ?? 'Chat',
          isGroup: e['isGroup'] ?? false,
          otherUserId: e['other'],
        );
      }),
      GoRoute(path: '/group/create', builder: (_, __) => const CreateGroupPage()),
      GoRoute(path: '/group/info/:id', builder: (_, state) =>
          GroupInfoPage(groupId: state.pathParameters['id']!)),
      // ---- Phase 6: Learning ----
      GoRoute(path: '/learning', builder: (_, __) => const LearningPage()),
      GoRoute(path: '/learning/course/:id', builder: (_, state) =>
          CourseDetailPage(courseId: state.pathParameters['id']!)),
      GoRoute(path: '/learning/course/:id/quiz', builder: (_, state) =>
          QuizPage(courseId: state.pathParameters['id']!)),
      GoRoute(path: '/learning/lesson/:id', builder: (_, state) {
        final e = (state.extra as Map?) ?? {};
        return LessonPage(
          lessonId: state.pathParameters['id']!,
          courseId: e['course_id'] ?? '',
          totalLessons: e['total'] ?? 1,
        );
      }),
      GoRoute(path: '/course/create', builder: (_, __) => const CreateCoursePage()),
      // ---- Phase 7: Games ----
      GoRoute(path: '/games', builder: (_, __) => const GamesPage()),
      GoRoute(path: '/game/play/:id', builder: (_, state) =>
          GamePlayerPage(gameId: state.pathParameters['id']!)),
      GoRoute(path: '/game/tictactoe/:id', builder: (_, state) =>
          TicTacToePage(matchId: state.pathParameters['id']!)),
      GoRoute(path: '/game/create', builder: (_, __) => const GameCreatorPage()),
      GoRoute(path: '/game/create/:id', builder: (_, state) =>
          GameCreatorPage(gameId: state.pathParameters['id'])),
      // ---- Phase 8: Live + TV ----
      GoRoute(path: '/live', builder: (_, __) => const LiveListPage()),
      GoRoute(path: '/live/go', builder: (_, __) => const GoLivePage()),
      GoRoute(path: '/live/:id', builder: (_, state) {
        final e = (state.extra as Map?) ?? {};
        return LiveRoomPage(
          streamId: state.pathParameters['id']!,
          isHost: e['isHost'] ?? false,
        );
      }),
      GoRoute(path: '/tv', builder: (_, __) => const TvPage()),
    ],
  );
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _paths = ['/home', '/shorts', '/create', '/fnf', '/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _paths.indexWhere((p) => location.startsWith(p));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(_paths[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.smartphone), label: 'Shorts'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'FNF'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}