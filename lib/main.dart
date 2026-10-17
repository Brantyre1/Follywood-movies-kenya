import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('FOLLYWOOD MOVIES KENYA', style: TextStyle(fontSize: 15, color: Colors.white)),
        actions: [
          if (pendingTitles > 0) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kOrange))),
          IconButton(icon: const Icon(Icons.system_update, color: kOrange), onPressed: () => AppUpdater.checkForUpdate(context)),
          IconButton(icon: const Icon(Icons.refresh, color: kOrange), onPressed: () { setState(() => loading = true); _loadAll(); }),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/bg.jpg'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 80, 12, 12),
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Search...', hintStyle: const TextStyle(color: Colors.white70), filled: true, fillColor: Colors.black.withOpacity(0.6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)),
              ),
            ),
            Expanded(
              child: loading ? const Center(child: CircularProgressIndicator(color: kOrange)) : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: 220),
                itemCount: filtered.length,
                itemBuilder: (context, i) => Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                  child: Column(
                    children: [
                      Expanded(child: Image.network(filtered[i].thumbUrl, fit: BoxFit.cover, width: double.infinity)),
                      Padding(padding: const EdgeInsets.all(8), child: Text(filtered[i].title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 12))),
                      Row(
                        children: [
                          Expanded(child: TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(videoId: filtered[i].id, title: filtered[i].title))), icon: const Icon(Icons.play_arrow, color: kOrange, size: 16), label: const Text('Watch', style: TextStyle(color: kOrange, fontSize: 10)))),
                          Expanded(child: TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DownloadTerminalScreen(videoId: filtered[i].id, title: filtered[i].title))), icon: const Icon(Icons.download, color: Colors.white, size: 16), label: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 10)))),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class PlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  const PlayerScreen({super.key, required this.videoId, required this.title});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}
class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('<html><body style="margin:0;padding:0;background:black;"><iframe width="100%" height="100%" src="https://www.youtube-nocookie.com/embed/${widget.videoId}?autoplay=1&playsinline=1&origin=https://www.youtube-nocookie.com" frameborder="0" allowfullscreen></iframe></body></html>', baseUrl: 'https://www.youtube-nocookie.com');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontSize: 14))),
      body: AspectRatio(aspectRatio: 16 / 9, child: WebViewWidget(controller: _controller)),
    );
  }
}
class DownloadTerminalScreen extends StatefulWidget {
  final String videoId;
  final String title;
  const DownloadTerminalScreen({super.key, required this.videoId, required this.title});
  @override
  State<DownloadTerminalScreen> createState() => _DownloadTerminalScreenState();
}
class _DownloadTerminalScreenState extends State<DownloadTerminalScreen> {
  double progress = 0;
  bool done = false;
  @override
  void initState() {
    super.initState();
    _dl();
  }
  Future<void> _dl() async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streams.getManifest(widget.videoId);
      final info = manifest.muxed.withHighestBitrate();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.title.replaceAll(" ", "_")}.mp4');
      final sink = file.openWrite();
      int downloaded = 0;
      await for (final chunk in yt.videos.streams.get(info)) {
        sink.add(chunk);
        downloaded += chunk.length;
        setState(() => progress = downloaded / info.size.totalBytes);
      }
      await sink.close();
      setState(() => done = true);
    } catch (e) { setState(() => done = true); }
    yt.close();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('DOWNLOADING', style: TextStyle(color: Color(0xFF00FF00)))),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        LinearProgressIndicator(value: progress, color: const Color(0xFF00FF00), backgroundColor: Colors.white10),
        const SizedBox(height: 20),
        Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF00FF00), fontSize: 24, fontFamily: 'monospace')),
        if (done) TextButton(onPressed: () => Navigator.pop(context), child: const Text('DONE', style: TextStyle(color: Color(0xFF00FF00)))),
      ])),
    );
  }
}
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Downloads')));
}
