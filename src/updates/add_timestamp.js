function(oldDoc, req) {
  // Parse the document body
  newDoc = JSON.parse(req.body)

  // Update documents only if a new document
  // is being added or if the revision ids match
  if (!oldDoc || oldDoc._rev === newDoc._rev) {

    // Add the id to the document if it's
    // not present, either from the request url
    // or use a random unique id.
    if (!oldDoc && !newDoc._id) {
      if (req.id) {
        newDoc._id = req.id;
      } else {
        newDoc._id = req.uuid;
      }
    }

    // Add a timestamp to the document
    newDoc.timestamp = new Date().toISOString();

    // Save the new document, and return a JSON-
    // serialized copy. Note that this will
    // contain only the old revision hash.
    return [newDoc, toJSON(newDoc)];
  } else {
    return [null, 'Update failed']
  }
}
