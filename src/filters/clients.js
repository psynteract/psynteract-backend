function(doc, req) {
  // Default parameters
  var session = typeof(req.query.session) != 'undefined' ?
    req.query.session : null;
  var include_session = typeof(req.query.include_session) != 'undefined' ?
    req.query.include_session : false;

  // Further checks
  var checks_passed = false;

  // First check whether the document belongs
  // to the session specified in the request parameters
  // (either because it is the relevant session doc,
  // or a client connected to the session)
  if (session) {
    if (doc._id == session || (doc.session && doc.session == session)) {
      checks_passed = true;
    } else {
      checks_passed = false;
    }
  } else {
    // If no session is specified, do not filter
    // docs according to this criterion
    checks_passed = true;
  }

  // Secondly, filter documents according to type
  // (only if previous checks have passed and a type is specified)
  if (checks_passed && req.query.type) {
    // Filter by type or include the session anyway,
    // if the appropriate flag is set; this is the
    // decisive criterion because we already know
    // that all other checks have passed.
    if ((doc.type && doc.type == req.query.type) ||
        (include_session && doc.type == 'session')) {
      return true;
    } else {
      return false;
    }
  } else {
    // If no document type is supplied,
    // return relevant documents regardless
    // of type.
    return checks_passed;
  }
}
