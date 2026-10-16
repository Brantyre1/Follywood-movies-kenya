import 'package:youtube_explode_dart_alpha/youtube_explode_dart_alpha.dart';

void main() async {
  final yt = YoutubeExplode();
  final channelId = 'UCdgwWRbltiP3rbwxqL555UA';
  
  // Method A - getUploads as a list
  try {
    print('--- Method A: getUploads().toList() ---');
    final videos = await yt.channels.getUploads(channelId).toList();
    print('Found: ${videos.length}');
    for (var v in videos.take(5)) print('  - ${v.title}');
  } catch (e) {
    print('ERROR A: $e');
  }
  
  // Method B - channel.videos
  try {
    print('\n--- Method B: channel with uploads ---');
    final channel = await yt.channels.get(channelId);
    print('Title: ${channel.title}');
    // Try fetching just the uploads playlist id
    print('Uploads playlist URL: ${channel.url}/videos');
  } catch (e) {
    print('ERROR B: $e');
  }
  
  // Method C - get last 30 uploads specifically
  try {
    print('\n--- Method C: getUploads take 30 ---');
    final videos = await yt.channels.getUploads(channelId).take(30).toList();
    print('Found: ${videos.length}');
  } catch (e) {
    print('ERROR C: $e');
  }
  
  yt.close();
}
