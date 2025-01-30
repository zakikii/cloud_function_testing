const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

// Import functions
const { getPosts } = require("./src/posts/getPosts");
const { createFilteredPost } = require("./src/posts/createPost");
const { addFilteredComment } = require("./src/comments/addComment");

// Export functions
exports.getPosts = getPosts;
exports.createFilteredPost = createFilteredPost;
exports.addFilteredComment = addFilteredComment;

exports.createPost = onCall(async (request) => {
  console.log("Request data:", request.data);
  console.log("Auth:", request.auth);

  if (!request.auth) {
    throw new Error("Must be logged in");
  }

  const { content } = request.data;
  if (!content) {
    throw new Error("Content is required");
  }

  try {
    const postData = {
      content: String(content),
      userId: String(request.auth.uid),
      userEmail: String(request.auth.token.email),
      createdAt: new Date().toISOString(),
      comments: [],
    };

    const docRef = await admin.firestore().collection("posts").add(postData);

    return {
      id: docRef.id,
      ...postData,
    };
  } catch (error) {
    console.error("Error creating post:", error);
    throw new Error("Error creating post");
  }
});

// Add Comment
exports.addComment = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Must be logged in");
  }

  const { postId, content } = request.data;

  // Log untuk debugging
  console.log("Adding comment for postId:", postId);
  console.log("Comment content:", content);

  if (!postId || !content) {
    throw new Error("PostId and content required");
  }

  try {
    // Buat objek comment
    const comment = {
      id: admin.firestore().collection("_").doc().id, // Generate unique ID
      content: String(content),
      userId: String(request.auth.uid),
      userEmail: String(request.auth.token.email),
      createdAt: new Date().toISOString(),
    };

    console.log("Comment object:", comment);

    // Dapatkan referensi dokumen post
    const postRef = admin.firestore().collection("posts").doc(postId);

    // Dapatkan data post saat ini
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw new Error("Post not found");
    }

    const currentData = postDoc.data();
    const comments = Array.isArray(currentData.comments)
      ? currentData.comments
      : [];

    // Tambahkan comment baru ke array
    comments.push(comment);

    // Update dokumen
    await postRef.update({
      comments: comments,
    });

    console.log("Comment added successfully");
    return { success: true, comment };
  } catch (error) {
    console.error("Error adding comment:", error);
    throw new Error(`Error adding comment: ${error.message}`);
  }
});

exports.editPost = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Must be logged in");
  }

  const { postId, content } = request.data;

  if (!postId || !content) {
    throw new Error("PostId and content required");
  }

  try {
    const postRef = admin.firestore().collection("posts").doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw new Error("Post not found");
    }

    // Verifikasi bahwa user adalah pemilik post
    const postData = postDoc.data();
    if (postData.userId !== request.auth.uid) {
      throw new Error("Not authorized to edit this post");
    }

    await postRef.update({
      content: content,
    });

    return { success: true };
  } catch (error) {
    console.error("Error editing post:", error);
    throw new Error("Error editing post");
  }
});

exports.deletePost = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Must be logged in");
  }

  const { postId } = request.data;

  if (!postId) {
    throw new Error("PostId required");
  }

  try {
    const postRef = admin.firestore().collection("posts").doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw new Error("Post not found");
    }

    // Verify that user is the owner of the post
    const postData = postDoc.data();
    if (postData.userId !== request.auth.uid) {
      throw new Error("Not authorized to delete this post");
    }

    await postRef.delete();

    return { success: true };
  } catch (error) {
    console.error("Error deleting post:", error);
    throw new Error(`Error deleting post: ${error.message}`);
  }
});

exports.deleteComment = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Must be logged in");
  }

  const { postId, commentId } = request.data;

  if (!postId || !commentId) {
    throw new Error("PostId and commentId required");
  }

  try {
    const postRef = admin.firestore().collection("posts").doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw new Error("Post not found");
    }

    const postData = postDoc.data();
    const comments = postData.comments || [];
    const commentIndex = comments.findIndex((c) => c.id === commentId);

    if (commentIndex === -1) {
      throw new Error("Comment not found");
    }

    // Verify comment ownership
    if (comments[commentIndex].userId !== request.auth.uid) {
      throw new Error("Not authorized to delete this comment");
    }

    comments.splice(commentIndex, 1);
    await postRef.update({ comments });
    return { success: true };
  } catch (error) {
    console.error("Error deleting comment:", error);
    throw new Error(`Error deleting comment: ${error.message}`);
  }
});

exports.editFilteredPost = onCall(async (request) => {
  if (!request.auth) throw new Error("Must be logged in");

  const { postId, content } = request.data;
  if (!postId || !content) throw new Error("PostId and content required");

  try {
    const postRef = admin.firestore().collection("posts").doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw new Error("Post not found");
    }

    const postData = postDoc.data();
    if (postData.userId !== request.auth.uid) {
      throw new Error("Not authorized to edit this post");
    }

    const filteredContent = filterBadWords(content);

    await postRef.update({
      content: filteredContent,
    });

    return { success: true };
  } catch (error) {
    console.error("Error editing post:", error);
    throw new Error("Error editing post");
  }
});

function filterBadWords(text) {
  const badWords = [
    "shit",
    "fuck",
    "anjing",
    "bangsat",
    "kontol",
    "memek",
    "jancok",
    "cuk",
    "asu",
    "babi",
    "kampret",
    "tolol",
    "goblok",
    "bodoh",
  ]; // Tambahkan kata-kata kasar lainnya sesuai kebutuhan

  let filteredText = text.toLowerCase();

  badWords.forEach((word) => {
    // Gunakan regex untuk mencocokkan kata dalam berbagai bentuk
    const regex = new RegExp(`\\b${word}\\b`, "gi");
    filteredText = filteredText.replace(regex, "*beep*");
  });

  return filteredText;
}
