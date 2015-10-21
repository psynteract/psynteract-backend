// Build a couchapp from the files in the src folder

var fs = require('fs'),
    path = require('path'),
    walk = require('walk'),
    mime = require('mime');


// Start from a minimal design document
var ddoc = {
  _id: '_design/psynteract',
  couchapp: {
    name: 'Psynteract',
    description: 'Interactive experiments'
  }
};

// Add attachments
var process_attachments = function() {
  return new Promise(function(resolve, reject) {
    // Define a handler that will add the file contents
    // to the ddoc as base64-encoded attachments
    var fileHandler = function(root, fileStats, next) {

      var filename_full = root + '/' + fileStats.name;
      var filename_attach = filename_full.substr(17);

      fs.readFile(filename_full, function(err, data) {
        if (err) throw err;
        o = {
          'content_type': mime.lookup(filename_full),
          'data': data.toString('base64')
        }
        ddoc['_attachments'][filename_attach] = o;
      });

      next();
    };

    ddoc['_attachments'] = {};

    // Add files in the repository
    var walker = walk.walk('src/_attachments');
    walker.on('file', fileHandler);
    walker.on('end', resolve);
  });
}

// Create a nested object structure
var nest = function(o, path, value) {
  var current_path = o;

  path.forEach(function(segment, i) {
    if (i < path.length - 1) {
      current_path = current_path[segment] = current_path[segment] || {};
    } else {
      current_path[segment] = value;
    }
  });

  return o;
};

// Add design functions: views, shows, filters, etc.
var process_functions = function() {
  return new Promise(function(resolve, reject) {
    var function_dirs = ['filters', 'lists', 'shows', 'updates', 'views'];

    // For these directories, add any included files to the
    // design document as strings
    var fileHandler = function(root, fileStats, next) {
      var filename_full = root + '/' + fileStats.name;
      var attach_path = filename_full.substr(4).split(path.sep);

      // Remove the extension from the path
      attach_path[attach_path.length-1] = path.parse(filename_full).name

      // Add the contents of the file to the ddoc as plain text
      fs.readFile(filename_full, function(err, data) {
        if (err) throw err;
        nest(ddoc, attach_path, data.toString('utf-8'));
      });

      // Continue
      next();
    }

    // Apply the handler specified above to the respective
    // directories.
    var p = function_dirs.map(function(d) {
      ddoc[d] = {}

      return new Promise(function(resolve, reject) {
        var walker = walk.walk('src/' + d)
        walker.on('file', fileHandler);
        walker.on('end', resolve);
      });
    })

    // Resolve the promise if all directories have been
    // processed
    Promise.all(p).then(resolve)
  })
}

process_attachments()
  .then(process_functions)
  .then(function(x) {
    // Write the couchapp.json to the file system
    fs.writeFile('backend.json', JSON.stringify(ddoc, null, 2), function(err, written, string) {
      if (err) throw err;
    });
  });
