import 'dart:async';

class PostUpdate {
  final int postId;
  final int likeCount;
  final bool isLiked;

  PostUpdate({
    required this.postId,
    required this.likeCount,
    required this.isLiked,
  });
}

class PostState {
  static final PostState _instance = PostState._internal();
  factory PostState() => _instance;
  PostState._internal();

  final _postUpdateController = StreamController<PostUpdate>.broadcast();
  Stream<PostUpdate> get onPostUpdate => _postUpdateController.stream;

  void updatePost(int postId, int likeCount, bool isLiked) {
    _postUpdateController.add(
      PostUpdate(postId: postId, likeCount: likeCount, isLiked: isLiked),
    );
  }
}
