import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FollywoodApp());
}

class FollywoodApp extends StatelessWidget {
  const FollywoodApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FOLLYWOOD MOVIES KENYA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B12),
        primaryColor: const Color(0xFFFFA500),
      ),
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
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1040), Color(0xFF0B0B12)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFA500), width: 3),
                ),
                child: const Icon(Icons.movie_filter,
                    size: 64, color: Color(0xFFFFA500)),
              ),
              const SizedBox(height: 30),
              const Text('FOLLYWOOD',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4)),
              const Text('MOVIES KENYA',
                  style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFFFFA500),
                      letterSpacing: 6)),
              const SizedBox(height: 60),
              const CircularProgressIndicator(color: Color(0xFFFFA500)),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final YoutubeExplode yt = YoutubeExplode();
  List<Video> allVideos = [];
  List<Video> filtered = [];
  bool loading = true;
  String? error;
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVideos();
    searchCtrl.addListener(_onSearch);
  }

  Future<void> _loadVideos() async {
    try {
      final channel = await yt.channels.getByHandle('@follywoodtopmovies');
      final uploads = await yt.channels.getUploads(channel.id);
      final list = await uploads.toList();
      setState(() {
        allVideos = list;
        filtered = list;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _onSearch() {
    final q = searchCtrl.text.toLowerCase();
    setState(() {
      filtered = q.isEmpty
          ? allVideos
          : allVideos.where((v) => v.title.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOLLYWOOD MOVIES KENYA',
            style: TextStyle(fontSize: 15, letterSpacing: 2)),
        backgroundColor: const Color(0xFF0B0B12),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1040), Color(0xFF0B0B12)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search movies...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFFFFA500)),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFFFA500)))
                  : error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('Error loading channel:\n$error',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12)),
                          ),
                        )
                      : filtered.isEmpty
                          ? const Center(
                              child: Text('No results.',
                                  style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final v = filtered[i];
                                return Card(
                                  color: Colors.white10,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    leading: Image.network(
                                      v.thumbnails.mediumResUrl,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.movie,
                                          color: Color(0xFFFFA500)),
                                    ),
                                    title: Text(v.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.white)),
                                    subtitle: Text(v.author,
                                        style: const TextStyle(
                                            color: Color(0xFFFFA500),
                                            fontSize: 11)),
                                    trailing: const Icon(Icons.download,
                                        color: Color(0xFFFFA500)),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  DownloadTerminalScreen(
                                                      video: v)));
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DownloadsScreen()));
        },
        backgroundColor: const Color(0xFFFFA500),
        icon: const Icon(Icons.folder, color: Colors.black),
        label: const Text('MY DOWNLOADS',
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    yt.close();
    super.dispose();
  }
}

class DownloadTerminalScreen extends StatefulWidget {
  final Video video;
  const DownloadTerminalScreen({super.key, required this.video});
  @override
  State<DownloadTerminalScreen> createState() => _DownloadTerminalScreenState();
}

class _DownloadTerminalScreenState extends State<DownloadTerminalScreen> {
  final List<String> lines = [];
  double progress = 0;
  bool done = false;

  void log(String msg) {
    setState(() {
      lines.add('> $msg');
    });
  }

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    final yt = YoutubeExplode();
    try {
      log('Initializing download...');
      log('Title: ${widget.video.title}');
      log('Author: ${widget.video.author}');
      log('Fetching manifest...');

      final manifest =
          await yt.videos.streams.getManifest(widget.video.id.value);
      final streamInfo = manifest.muxed.withHighestBitrate();
      final stream = yt.videos.streams.get(streamInfo);

      log('Stream: ${streamInfo.qualityLabel} | ${streamInfo.container.name}');
      log('Size: ${(streamInfo.size.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB');
      log('Saving to app storage...');

      final dir = await getApplicationDocumentsDirectory();
      final safe = widget.video.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final filename = '${safe}_${widget.video.id.value}.mp4';
      final file = File('${dir.path}/$filename');

      final sink = file.openWrite();
      int downloaded = 0;
      final total = streamInfo.size.totalBytes;

      await for (final chunk in stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        final pct = downloaded / total;
        setState(() => progress = pct);
        if (downloaded % (1024 * 1024) < chunk.length) {
          log('Progress: ${(pct * 100).toStringAsFixed(1)}%');
        }
      }

      await sink.close();
      log('Download complete.');
      log('Saved: $filename');
      setState(() => done = true);
    } catch (e) {
      log('ERROR: $e');
      setState(() => done = true);
    } finally {
      yt.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('DOWNLOAD TERMINAL',
            style: TextStyle(
                fontSize: 14,
                color: Color(0xFF00FF00),
                letterSpacing: 2)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              color: const Color(0xFF00FF00),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text('${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: const Color(0xFF00FF00))),
                child: ListView.builder(
                  itemCount: lines.length,
                  itemBuilder: (_, i) => Text(
                    lines[i],
                    style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 12,
                        fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            if (done)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('BACK',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory(dir.path);
    final list = d.listSync().where((f) => f.path.endsWith('.mp4')).toList();
    setState(() => files = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY DOWNLOADS',
            style: TextStyle(fontSize: 15, letterSpacing: 2)),
        backgroundColor: const Color(0xFF0B0B12),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1040), Color(0xFF0B0B12)]),
        ),
        child: files.isEmpty
            ? const Center(
                child: Text('No downloads yet.',
                    style: TextStyle(color: Colors.white54)))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (_, i) {
                    final f = files[i];
                    final name = f.path.split('/').last;
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.movie,
                            color: Color(0xFFFFA500)),
                        title: Text(name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${(File(f.path).lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
                            style: const TextStyle(
                                color: Color(0xFFFFA500), fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent),
                          onPressed: () {
                            File(f.path).deleteSync();
                            _load();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
