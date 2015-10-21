# Psynteract Backend

__Web-based backend for the interactive experiments using the psynteract library.__

This repository is mostly for development purposes. You are very welcome to poke around and contribute -- if you are looking to build experiments using psynteract, you might be looking for the [OpenSesame](//github.com/felixhenninger/psynteract-os) or [pure Python](//github.com/felixhenninger/psynteract-py) libraries for psynteract, which come bundled with this backend and an installer.

## Status

This software is currently in beta: All core functionality is present and relatively stable.

## Development

If you would like to alter the design or behavior of the backend, you are very welcome to do so!

To work with the repository, you will need `node` and `npm`. Using these, the dependencies for the later steps can be installed by running the following commands within your copy of the repository:

```bash
npm install # Install npm packages that are used in the build process
bower install # Download third-party libraries
```

Thereafter, the package can be (re)built with the following commands:

```bash
gulp # Compile CoffeeScript and copy third-party files
node build.js # Build a JSON blob to be uploaded to the database
```

Finally, the resulting file `backend.json` can be uploaded to a database using the following command:

```bash
# Upload the JSON blob to a CouchDB instance
curl -X PUT http://[couchdb_host]/[db_name]/_design/psynteract -d @backend.json
```
