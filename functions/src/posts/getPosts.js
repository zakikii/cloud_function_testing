const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

exports.getPosts = onCall(async (request) => {
  if (!request.auth) throw new Error("Must be logged in");

  try {
    const postsRef = admin.firestore().collection("posts");
    const snapshot = await postsRef.orderBy("createdAt", "desc").get();

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const processedComments = (data.comments || []).map((comment) => ({
        id: String(comment.id || ""),
        content: String(comment.content || ""),
        userId: String(comment.userId || ""),
        userEmail: String(comment.userEmail || ""),
        createdAt:
          typeof comment.createdAt === "string"
            ? comment.createdAt
            : comment.createdAt?._seconds
            ? new Date(comment.createdAt._seconds * 1000).toISOString()
            : new Date().toISOString(),
      }));

      return {
        id: String(doc.id),
        content: String(data.content || ""),
        userId: String(data.userId || ""),
        userEmail: String(data.userEmail || ""),
        createdAt: data.createdAt,
        comments: processedComments,
      };
    });
  } catch (error) {
    throw new Error("Error getting posts");
  }
});
