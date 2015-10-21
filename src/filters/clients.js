function(doc, req) {
  // Legacy api compliance
  var session = typeof(req.query.key) != 'undefined' ? req.query.key : null;
  // It would ideal to use the session parameter only
  var session = typeof(req.query.session) != 'undefined' ? req.query.session : session;

  var checks_passed = false;

  if (session) {
    if (doc._id == session || (doc.session && doc.session == session)) {
      checks_passed = true;
    } else {
      checks_passed = false;
    }
  } else {
    checks_passed = true;
  }

  if (checks_passed && req.query.type) {
    if (doc.type && doc.type == req.query.type) {
      return true;
    } else {
      return false;
    }
  } else {
    return checks_passed;
  }
}
