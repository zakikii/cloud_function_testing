const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const filterBadWords = require("../utils/filterBadWords");

exports.createFilteredPost = onCall(async (request) => {
  if (!request.auth) throw new Error("Must be logged in");

  const { content } = request.data;
  if (!content) throw new Error("Content is required");

  const filteredContent = filterBadWords(content);

  try {
    const postData = {
      content: filteredContent,
      userId: request.auth.uid,
      userEmail: request.auth.token.email,
      createdAt: new Date().toISOString(),
      comments: [],
    };

    const docRef = await admin.firestore().collection("posts").add(postData);
    return { id: docRef.id, ...postData };
  } catch (error) {
    throw new Error("Error creating post");
  }
});
