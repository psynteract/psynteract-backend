function(doc) {
  if (doc.type == "client") {
    emit(doc.session, doc);
  }
}
