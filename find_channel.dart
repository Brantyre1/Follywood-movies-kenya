import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    final channel = await yt.channels.getByHandle('@follywoodtopmovies');
    print('Channel ID: ${channel.id}');
    print('Channel Name: ${channel.title}');
    print('Channel URL: ${channel.url}');
    
    final videos = await yt.channels.getUploads(channel.id).take(5).toList();
    print('Found ${videos.length} videos:');
    for (var v in videos) {
      print('  - ${v.title}');
    }
  } catch (e) {
    print('ERROR: $e');
  }
  yt.close();
}
