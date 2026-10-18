import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
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
              DrawerHeader(
                decoration: const BoxDecoration(color: kOrange),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
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
          Expanded(
            child: loading ? const Center(child: CircularProgressIndicator(color: kOrange)) : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: 220),
              itemCount: filtered.length,
              itemBuilder: (context, i) => Container(
                decoration: BoxDecoration(color: const Color(0xFF1C1C22), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: Column(
                  children: [
                    Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(filtered[i].thumbUrl, fit: BoxFit.cover, width: double.infinity))),
                    Padding(padding: const EdgeInsets.all(8), child: Text(filtered[i].title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12))),
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
    );
  }

  Future<void> _loadAll() async {
    const String apiKey = 'AIzaSyCn_yGtVtDFd-C7D-eJHGCE1qdY19gxDK8';
    const String uploadsPlaylistId = 'UUdgwWRbltiP3rbwxqL555UA'; 
    
    try {
      final url = Uri.parse('https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=$uploadsPlaylistId&key=$apiKey');
      final resp = await http.get(url).timeout(const Duration(seconds: 15));
      
      if (resp.statusCode != 200) throw Exception('API Error: ${resp.statusCode}');
      
      final data = jsonDecode(resp.body);
      final items = data['items'] as List;
      
      final List<VideoItem> loadedVideos = [];
      for (var item in items) {
        final id = item['snippet']['resourceId']['videoId'];
        final title = item['snippet']['title'];
        loadedVideos.add(VideoItem(id: id, title: title));
      }
      
      setState(() {
        allVideos = loadedVideos;
        filtered = allVideos;
        loading = false;
        pendingTitles = 0;
      });
    } catch (e) { 
      setState(() => loading = false); 
    }
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.youtube-nocookie.com/embed/${widget.videoId}?autoplay=1&playsinline=1'), headers: {'Referer': 'https://com.follywood.follywood_movies_kenya'});
  }
  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), title: Text(widget.title, style: const TextStyle(fontSize: 14)), actions: [IconButton(icon: const Icon(Icons.open_in_new, color: kOrange), onPressed: () async { final url = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}'); if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); } })]),
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
  void initState() { super.initState(); _dl(); }
  Future<void> _dl() async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streams.getManifest(widget.videoId);
      final info = manifest.muxed.withHighestBitrate();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.title.replaceAll(" ", "_")}.mp4');
      final sink = file.openWrite();
      int downloaded = 0;
      await for (final chunk in yt.videos.streams.get(info)) { sink.add(chunk); downloaded += chunk.length; setState(() => progress = downloaded / info.size.totalBytes); }
      await sink.close();
      setState(() => done = true);
    } catch (e) { setState(() => done = true); }
    yt.close();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(title: const Text('DOWNLOADING', style: TextStyle(color: Color(0xFF00FF00)))), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [LinearProgressIndicator(value: progress, color: const Color(0xFF00FF00), backgroundColor: Colors.white10), const SizedBox(height: 20), Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF00FF00), fontSize: 24, fontFamily: 'monospace')), if (done) TextButton(onPressed: () => Navigator.pop(context), child: const Text('DONE', style: TextStyle(color: Color(0xFF00FF00))))])));
  }
}
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}
class _DownloadsScreenState extends State<DownloadsScreen> {
  List<FileSystemEntity> files = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final dir = await getApplicationDocumentsDirectory();
    final list = Directory(dir.path).listSync().where((f) => f.path.endsWith('.mp4')).toList();
    setState(() => files = list);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFF0F0F13), appBar: AppBar(backgroundColor: const Color(0xFF0F0F13), title: const Text('MY DOWNLOADS', style: TextStyle(fontSize: 15, color: Colors.white))), body: files.isEmpty ? const Center(child: Text('No downloads yet.', style: TextStyle(color: Colors.white54))) : ListView.builder(itemCount: files.length, itemBuilder: (_, i) {
      final f = files[i];
      final name = f.path.split('/').last;
      final size = (File(f.path).lengthSync() / 1024 / 1024).toStringAsFixed(1);
      return ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kOrange.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.movie, color: kOrange)),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
        subtitle: Text('$size MB', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () { File(f.path).deleteSync(); _load(); }),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocalPlayerScreen(filePath: f.path))),
      );
    }));
  }
}
class LocalPlayerScreen extends StatefulWidget {
  final String filePath;
  const LocalPlayerScreen({super.key, required this.filePath});
  @override
  State<LocalPlayerScreen> createState() => _LocalPlayerScreenState();
}
class _LocalPlayerScreenState extends State<LocalPlayerScreen> {
  late VideoPlayerController _controller;
  @override
  void initState() { super.initState(); _controller = VideoPlayerController.file(File(widget.filePath))..initialize().then((_) { setState(() {}); _controller.play(); }); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), title: const Text('PLAYING', style: TextStyle(color: Colors.white, fontSize: 14))), body: Center(child: _controller.value.isInitialized ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: Stack(alignment: Alignment.bottomCenter, children: [VideoPlayer(_controller), VideoProgressIndicator(_controller, allowScrubbing: true), FloatingActionButton(backgroundColor: Colors.transparent, onPressed: () { setState(() { _controller.value.isPlaying ? _controller.pause() : _controller.play(); }); }, child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 50))])) : const CircularProgressIndicator(color: kOrange)));
  }
}
