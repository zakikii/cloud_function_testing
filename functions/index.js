const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

// Import functions
const { createFilteredPost } = require("./src/posts/createPost");
const { addComment } = require("./src/comments/addComment");
const { editFilteredPost } = require("./src/posts/editPost");

// Export functions
exports.createFilteredPost = createFilteredPost;
exports.addComment = addComment;
exports.editFilteredPost = editFilteredPost;
