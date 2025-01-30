function filterBadWords(text) {
  const badWords = [
    "shit",
    "fuck",
    "anjing",
    "bangsat",
    "jancok",
    "cuk",
    "asu",
    "babi",
    "kampret",
    "tolol",
    "goblok",
    "bodoh",
  ];

  let filteredText = text.toLowerCase();

  badWords.forEach((word) => {
    const regex = new RegExp(`\\b${word}\\b`, "gi");
    filteredText = filteredText.replace(regex, "*beep*");
  });

  return filteredText;
}

module.exports = filterBadWords;
