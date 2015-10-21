function(doc) {
  if (doc.type == "session") {
    emit(doc._id, doc);
  }
}

