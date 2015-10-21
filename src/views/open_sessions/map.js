function(doc) {
  if (doc.type == "session" && doc.status == "open") {
    emit(doc.opened, doc._id);
  }
}
