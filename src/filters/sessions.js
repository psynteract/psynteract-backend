function(doc, req) {
  if (doc.type == "session" || doc._deleted) {
    return true;
  } else {
    return false;
  }
};
