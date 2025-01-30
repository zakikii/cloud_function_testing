import 'package:cloud_function_testing/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/post.dart';
import '../../data/services/post_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PostService _postService = PostService();
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Future<List<Post>>? _postsFuture;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshPosts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
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
      // Scroll to top after posting
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search posts...',
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            prefixIcon: const Icon(Icons.search),
            prefixIconColor: Colors.grey[600],
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Colors.black,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 20.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList(List<Post> posts) {
    final filteredPosts = posts.where((post) {
      final searchLower = _searchQuery.toLowerCase();
      return post.content.toLowerCase().contains(searchLower) ||
          post.userEmail.toLowerCase().contains(searchLower);
    }).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8), // Light off-white background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFA), // Slightly lighter at top
              Color(0xFFF5F5F5), // Slightly darker at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good evening',
                          style: textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          'My Friend',
                          style: textTheme.headlineMedium?.copyWith(
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showCreatePostDialog(context),
                    ),
                  ],
                ),
              ),

              _buildSearchBar(),

              // Categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildCategoryChip('All', true),
                    _buildCategoryChip('General', false),
                    _buildCategoryChip('COVID-19', false),
                    _buildCategoryChip('Allergies', false),
                  ],
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
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No posts yet'));
                    }
                    return _buildPostsList(snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) async {
          if (index == 1) {
            // Handle logout
            await FirebaseAuth.instance.signOut();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            backgroundColor: Colors.white,
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_outlined),
            activeIcon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {},
        backgroundColor: Colors.white,
        selectedColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserPost = currentUser?.uid == post.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color.fromARGB(255, 196, 197, 198),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'COVID-19',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isCurrentUserPost)
                PopupMenuButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Edit'),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _showEditDialog(context, post),
                      ),
                    ),
                    PopupMenuItem(
                      child: const Text('Delete'),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _showDeleteDialog(context, post.id),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${post.userEmail} • ${DateFormatter.formatDateTime(post.createdAt)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 20),
              const SizedBox(width: 4),
              Text('11'),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 20),
              const SizedBox(width: 4),
              Text('${post.comments?.length ?? 0} replies'),
            ],
          ),

          // Comments Section
          if (post.comments?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: post.comments?.length ?? 0,
              padding: const EdgeInsets.only(top: 16),
              itemBuilder: (context, index) {
                final comment = post.comments![index];
                return _buildCommentTile(post.id, comment);
              },
            ),
          ],

          // Add Comment Section
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
          _buildAddCommentSection(post.id),
        ],
      ),
    );
  }

  Widget _buildCommentTile(String postId, Comment comment) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserComment = currentUser?.uid == comment.userId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey[200],
            child: Text(
              comment.userEmail[0].toUpperCase(),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userEmail,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatDateTime(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
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
          if (isCurrentUserComment)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () =>
                  _showDeleteCommentDialog(context, postId, comment.id),
              color: Colors.grey[600],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildAddCommentSection(String postId) {
    final TextEditingController commentController = TextEditingController();

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey[200],
          child: Text(
            FirebaseAuth.instance.currentUser?.email?[0].toUpperCase() ?? 'U',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            if (commentController.text.isEmpty) return;

            try {
              await _postService.addComment(postId, commentController.text);
              commentController.clear();
              _refreshPosts(); // Refresh to show new comment
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding comment: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Post'),
        ),
      ],
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _postController,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _createPost();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Post'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Post post) {
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
          maxLines: 3,
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
                await _postService.editPost(post.id, editController.text);
                _refreshPosts();
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

  void _showDeleteDialog(BuildContext context, String postId) {
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
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _postService.deletePost(postId);
                _refreshPosts();
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

  void _showDeleteCommentDialog(
      BuildContext context, String postId, String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _postService.deleteComment(postId, commentId);
                _refreshPosts();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting comment: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
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
}

class PostCard extends StatelessWidget {
  final Post post;
  final PostService postService;
  final VoidCallback onPostUpdated;
  final Function(BuildContext, String, String) onDeleteComment;

  const PostCard({
    super.key,
    required this.post,
    required this.postService,
    required this.onPostUpdated,
    required this.onDeleteComment,
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
                  onDeleteComment: (postId, commentId) =>
                      onDeleteComment(context, postId, commentId),
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
  final Function(String, String) onDeleteComment;

  const _CommentTile({
    required this.comment,
    required this.postId,
    required this.postService,
    required this.onCommentDeleted,
    required this.onDeleteComment,
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
              onPressed: () => onDeleteComment(postId, comment.id),
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
