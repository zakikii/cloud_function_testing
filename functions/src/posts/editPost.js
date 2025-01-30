const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const filterBadWords = require("../utils/filterBadWords");

exports.editFilteredPost = onCall(async (request) => {
  if (!request.auth) throw new Error("Must be logged in");

  const { postId, content } = request.data;
  if (!postId || !content) throw new Error("PostId and content are required");

  try {
    // Get post reference
    const postRef = admin.firestore().collection("posts").doc(postId);
    const post = await postRef.get();

    // Check if post exists
    if (!post.exists) {
      throw new Error("Post not found");
    }

    // Check if user owns the post
    if (post.data().userId !== request.auth.uid) {
      throw new Error("Not authorized to edit this post");
    }

    // Filter the content
    const filteredContent = filterBadWords(content);

    // Update the post
    await postRef.update({
      content: filteredContent,
    });

    return {
      success: true,
      content: filteredContent,
    };
  } catch (error) {
    console.error("Error editing post:", error);
    throw new Error(`Error editing post: ${error.message}`);
  }
});
