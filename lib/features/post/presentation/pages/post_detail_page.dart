import 'package:flutter/material.dart';
import '../../data/models/post.dart';
import '../../data/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  Post? _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  Future<void> _refreshPost() async {
    try {
      final updatedPost = await _postService.getPosts();
      final currentPost = updatedPost.firstWhere((p) => p.id == widget.post.id);
      if (mounted) {
        setState(() {
          _currentPost = currentPost;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing post: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    try {
      await _postService.addComment(
        widget.post.id,
        _commentController.text,
      );
      _commentController.clear();
      await _refreshPost(); // Tunggu refresh selesai
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _currentPost ?? widget.post;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.orange.shade50,
            Colors.white,
          ],
          stops: const [
            0.1,
            0.3,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Back to Post',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.arrowLeft,
              size: 20,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCB7258).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'New Post',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCB7258),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (post.userId == currentUser?.uid)
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => _buildActionSheet(),
                          );
                        },
                        child: const FaIcon(
                          FontAwesomeIcons.ellipsis,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post.content,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      post.userEmail.split('@')[0],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      ' • ${DateFormatter.formatDateTime(post.createdAt)}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.heart,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '11',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const FaIcon(
                      FontAwesomeIcons.comment,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.comments?.length ?? 0} replies',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Comments',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCommentsList(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildCommentInput(),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _addComment,
            icon: const FaIcon(
              FontAwesomeIcons.paperPlane,
              size: 20,
              color: Color(0xFFCB7258),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    final post = _currentPost ?? widget.post;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: post.comments?.length ?? 0,
      itemBuilder: (context, index) {
        final comment = post.comments![index];
        return _buildCommentTile(comment);
      },
    );
  }

  Widget _buildCommentTile(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFCB7258).withOpacity(0.1),
            child: Text(
              comment.userEmail[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: const Color(0xFFCB7258),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comment.userEmail.split('@')[0],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (comment.userId == currentUser?.uid)
                        GestureDetector(
                          onTap: () => _showCommentActionSheet(comment.id),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.ellipsisVertical,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.formatDateTime(comment.createdAt),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentActionSheet(String commentId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteCommentDialog(commentId);
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.trash,
                      size: 16,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Comment',
                      style: GoogleFonts.poppins(
                        color: Colors.red[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Comment?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _postService.deleteComment(widget.post.id, commentId);
                await _refreshPost();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting comment: $e')),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Post'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement edit post
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Post'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement delete post
            },
          ),
        ],
      ),
    );
  }
}
