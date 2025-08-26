import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

/// Displays a video player along with a simple comments section.
///
/// This page fetches the video document by its Firestore ID and plays the
/// video using the [video_player] package. Below the player it shows a
/// list of comments related to this video and provides an input box for
/// authenticated users to add new comments. Comments are stored in the
/// `comments` collection with a `contentId` pointing to the current video.
class VideoPage extends StatefulWidget {
  /// ID of the video document in Firestore.
  final String videoId;

  const VideoPage({super.key, required this.videoId});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  User? _user;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
    _loadVideo();
  }

  /// Loads the video document from Firestore and initializes the player.
  Future<void> _loadVideo() async {
    final doc = await FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.videoId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final url = data['videoUrl'] as String?;
      if (url != null) {
        _controller = VideoPlayerController.network(url);
        _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاهدة الفيديو'),
      ),
      body: Column(
        children: [
          // Video player
          if (_controller != null)
            FutureBuilder<void>(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  );
                } else {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            )
          else
            const SizedBox(
              height: 200,
              child: Center(child: Text('تعذر تحميل الفيديو')),
            ),
          const Divider(),
          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('contentId', isEqualTo: widget.videoId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data?.docs ?? [];
                if (comments.isEmpty) {
                  return const Center(child: Text('لا توجد تعليقات بعد'));
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    final text = data['text'] as String? ?? '';
                    final userId = data['userId'] as String? ?? '';
                    final likes = data['likes'] as List<dynamic>? ?? [];
                    final isLiked = _user != null && likes.contains(_user!.uid);
                    return ListTile(
                      title: Text(text),
                      subtitle: Text(userId),
                      trailing: IconButton(
                        icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : null),
                        onPressed: () async {
                          if (_user == null) return;
                          final commentRef = comments[index].reference;
                          await FirebaseFirestore.instance.runTransaction((tx) async {
                            final fresh = await tx.get(commentRef);
                            final freshData = fresh.data() as Map<String, dynamic>;
                            final freshLikes = (freshData['likes'] as List<dynamic>? ?? [])
                                .cast<String>();
                            if (freshLikes.contains(_user!.uid)) {
                              freshLikes.remove(_user!.uid);
                            } else {
                              freshLikes.add(_user!.uid);
                            }
                            tx.update(commentRef, {'likes': freshLikes});
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Comment input
          if (_user != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'أضف تعليقًا...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final text = _commentController.text.trim();
                      if (text.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('comments').add({
                          'contentId': widget.videoId,
                          'userId': _user!.uid,
                          'text': text,
                          'likes': <String>[],
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        _commentController.clear();
                      }
                    },
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('يجب تسجيل الدخول لإضافة تعليق'),
            ),
        ],
      ),
    );
  }
}