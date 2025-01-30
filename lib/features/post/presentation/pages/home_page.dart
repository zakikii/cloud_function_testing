import 'package:cloud_function_testing/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/post.dart';
import '../../data/services/post_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PostService _postService = PostService();
  final TextEditingController _postController = TextEditingController();
  Future<List<Post>>? _postsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = _postService.getPosts();
    });
  }

  Future<void> _createPost() async {
    if (_postController.text.isEmpty) return;

    try {
      await _postService.createPost(_postController.text);
      _postController.clear();
      _refreshPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Post Creation Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      FirebaseAuth.instance.currentUser?.email?[0]
                              .toUpperCase() ??
                          'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _createPost,
                  ),
                ],
              ),
            ),
          ),
          // Posts List
          Expanded(
            child: FutureBuilder<List<Post>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet'));
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshPosts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return PostCard(
                        post: post,
                        postService: _postService,
                        onPostUpdated: _refreshPosts,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final PostService postService;
  final VoidCallback onPostUpdated;

  const PostCard({
    super.key,
    required this.post,
    required this.postService,
    required this.onPostUpdated,
  });

  void _showEditDialog(BuildContext context) {
    final editController = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            hintText: 'Edit your post...',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await postService.editPost(post.id, editController.text);
                onPostUpdated();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error editing post: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await postService.deletePost(post.id);
                onPostUpdated();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting post: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserPost = currentUser?.uid == post.userId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                post.userEmail[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              post.userEmail,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormatter.formatDateTime(post.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: isCurrentUserPost
                ? PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _showEditDialog(context),
                        ),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _showDeleteDialog(context),
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          // Post Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              post.content,
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Comments Section
          if (post.comments?.isNotEmpty ?? false) ...[
            const Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: post.comments?.length ?? 0,
              itemBuilder: (context, index) {
                final comment = post.comments![index];
                return _CommentTile(
                  comment: comment,
                  postId: post.id,
                  postService: postService,
                  onCommentDeleted: onPostUpdated,
                );
              },
            ),
          ],

          // Add Comment Section
          _AddCommentSection(
            postId: post.id,
            postService: postService,
            onCommentAdded: onPostUpdated,
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final String postId;
  final PostService postService;
  final VoidCallback onCommentDeleted;

  const _CommentTile({
    required this.comment,
    required this.postId,
    required this.postService,
    required this.onCommentDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserComment = currentUser?.uid == comment.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(
              comment.userEmail[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userEmail,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatDateTime(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          // Delete Button
          if (isCurrentUserComment)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () async {
                try {
                  await postService.deleteComment(postId, comment.id);
                  onCommentDeleted();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting comment: $e')),
                    );
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

class _AddCommentSection extends StatefulWidget {
  final String postId;
  final PostService postService;
  final VoidCallback onCommentAdded;

  const _AddCommentSection({
    required this.postId,
    required this.postService,
    required this.onCommentAdded,
  });

  @override
  State<_AddCommentSection> createState() => _AddCommentSectionState();
}

class _AddCommentSectionState extends State<_AddCommentSection> {
  final commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              currentUser?.email?[0].toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            iconSize: 20,
            onPressed: () async {
              if (commentController.text.isEmpty) return;
              try {
                await widget.postService.addComment(
                  widget.postId,
                  commentController.text,
                );
                commentController.clear();
                widget.onCommentAdded();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding comment: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
