const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const filterBadWords = require("../utils/filterBadWords");

exports.addFilteredComment = onCall(async (request) => {
  if (!request.auth) throw new Error("Must be logged in");

  const { postId, content } = request.data;
  if (!postId || !content) throw new Error("PostId and content required");

  const filteredContent = filterBadWords(content);

  try {
    const comment = {
      id: admin.firestore().collection("_").doc().id,
      content: filteredContent,
      userId: request.auth.uid,
      userEmail: request.auth.token.email,
      createdAt: new Date().toISOString(),
    };

    const postRef = admin.firestore().collection("posts").doc(postId);
    await postRef.update({
      comments: admin.firestore.FieldValue.arrayUnion(comment),
    });

    return { success: true, comment };
  } catch (error) {
    throw new Error(`Error adding comment: ${error.message}`);
  }
});
