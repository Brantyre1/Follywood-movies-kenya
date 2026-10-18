import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'updater.dart';

const String CHANNEL_URL = 'https://www.youtube.com/@follywoodtopmovies/videos';
const String DESKTOP_UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
const Color kOrange = Color(0xFFFFA500);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FollywoodApp());
}

class FollywoodApp extends StatelessWidget {
  const FollywoodApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, primaryColor: kOrange),
      home: const SplashScreen(),
    );
  }
}
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.black, body: Center(child: Icon(Icons.movie_filter, color: kOrange, size: 80)));
  }
}
class VideoItem {
  final String id;
  String title;
  VideoItem({required this.id, required this.title});
  String get thumbUrl => 'https://i.ytimg.com/vi/$id/mqdefault.jpg';
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  List<VideoItem> allVideos = [];
  List<VideoItem> filtered = [];
  bool loading = true;
  int pendingTitles = 0;
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
    searchCtrl.addListener(() {
      final q = searchCtrl.text.toLowerCase();
      setState(() => filtered = q.isEmpty ? allVideos : allVideos.where((v) => v.title.toLowerCase().contains(q)).toList());
    });
  }

  Future<void> _loadAll() async {
    try {
      final resp = await http.get(Uri.parse(CHANNEL_URL), headers: {'User-Agent': DESKTOP_UA}).timeout(const Duration(seconds: 12));
      final ids = RegExp(r'"videoId":"([A-Za-z0-9_-]{11})"').allMatches(resp.body).map((m) => m.group(1)!).toSet().toList();
      setState(() {
        allVideos = ids.map((id) => VideoItem(id: id, title: 'Loading...')).toList();
        filtered = allVideos;
        loading = false;
        pendingTitles = ids.length;
      });
      for (var id in ids) {
        final r = await http.get(Uri.parse('https://www.youtube.com/watch?v=$id'), headers: {'User-Agent': DESKTOP_UA});
        final m = RegExp(r'<meta name="title" content="([^"]*)"').firstMatch(r.body);
        if (m != null) {
          var t = m.group(1)!.replaceAll(' - YouTube', '').replaceAll('&amp;', '&');
          final idx = allVideos.indexWhere((v) => v.id == id);
          if (idx >= 0 && mounted) setState(() { allVideos[idx].title = t; filtered = List.from(allVideos); pendingTitles--; });
        }
      }
    } catch (e) { setState(() => loading = false); }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF16161A),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: kOrange),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.movie_filter, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text('FOLLYWOOD', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title: const Text('Home', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.download_done, color: kOrange),
                title: const Text('My Downloads', style: TextStyle(color: kOrange)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        title: const Text('FOLLYWOOD MOVIES KENYA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.2)),
        actions: [
          if (pendingTitles > 0)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kOrange)),
            ),
          IconButton(icon: const Icon(Icons.system_update, color: kOrange), onPressed: () => AppUpdater.checkForUpdate(context)),
          IconButton(icon: const Icon(Icons.refresh, color: kOrange), onPressed: () { setState(() { loading = true; }); _loadAll(); }),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search movies...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1C22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  }
}
