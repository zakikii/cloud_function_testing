const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const filterBadWords = require("../utils/filterBadWords");

exports.addComment = onCall(async (request) => {
  if (!request.auth) throw new Error("Must be logged in");

  const { postId, content } = request.data;
  if (!postId || !content) throw new Error("PostId and content are required");

  const filteredContent = filterBadWords(content);

  try {
    const comment = {
      id: admin.firestore().collection("_").doc().id, // Generate unique ID
      content: filteredContent,
      userId: request.auth.uid,
      userEmail: request.auth.token.email,
      createdAt: new Date().toISOString(),
    };

    const postRef = admin.firestore().collection("posts").doc(postId);
    const post = await postRef.get();

    if (!post.exists) {
      throw new Error("Post not found");
    }

    // Get existing comments
    const currentComments = post.data().comments || [];

    // Add new comment
    const updatedComments = [...currentComments, comment];

    // Update post with new comments array
    await postRef.update({
      comments: updatedComments,
    });

    return { success: true, comment };
  } catch (error) {
    console.error("Error adding comment:", error);
    throw new Error(`Error adding comment: ${error.message}`);
  }
});
