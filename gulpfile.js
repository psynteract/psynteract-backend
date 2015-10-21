var gulp = require('gulp');
var coffee = require('gulp-coffee');
var header = require('gulp-header');

var banner = [
  '// psynteract-backend -- Control panel for interactive experiments with psynteract',
  '// (c) 2015- Felix Henninger, Pascal Kieslich & contributors',
  '// The psynteract backend is licensed under the GPLv3 license.\n\n'
  ].join('\n');

gulp.task('compile', function() {
  return gulp.src(['src/_attachments/js/*.coffee'])
    .pipe(coffee({bare: true}))
    .pipe(header(banner))
    .pipe(gulp.dest('src/_attachments/js'));
});

gulp.task('dependencies', function() {
  // Lodash and moment.js
  gulp.src(['bower_components/lodash/lodash.min.js']).pipe(gulp.dest('src/_attachments/vendor/lodash'));
  gulp.src(['bower_components/moment/moment.js']).pipe(gulp.dest('src/_attachments/vendor/moment.js'));

  // JQuery and JQuery-ui
  gulp.src(['bower_components/jquery/dist/jquery.min.js']).pipe(gulp.dest('src/_attachments/vendor/jquery'));
  gulp.src(['bower_components/jquery-migrate/jquery-migrate.min.js']).pipe(gulp.dest('src/_attachments/vendor/jquery'));
  gulp.src(['bower_components/jquery-ui/jquery-ui.min.js']).pipe(gulp.dest('src/_attachments/vendor/jquery-ui'));

  // Backbone.js and backbone-couchdb
  gulp.src(['bower_components/backbone/backbone-min.js']).pipe(gulp.dest('src/_attachments/vendor/backbone.js'));
  gulp.src(['bower_components/backbone-couchdb/backbone-couchdb.js']).pipe(gulp.dest('src/_attachments/vendor/backbone-couchdb'));

  // marionette.js
  gulp.src(['bower_components/backbone.marionette/lib/backbone.marionette.min.js']).pipe(gulp.dest('src/_attachments/vendor/backbone.marionette'));
  gulp.src(['bower_components/backbone.wreqr/lib/backbone.wreqr.min.js']).pipe(gulp.dest('src/_attachments/vendor/backbone.marionette'));
  gulp.src(['bower_components/backbone.babysitter/lib/backbone.babysitter.min.js']).pipe(gulp.dest('src/_attachments/vendor/backbone.marionette'));

  // backbone-modal
  gulp.src(['bower_components/backbone-modal/backbone.marionette.modals-min.js']).pipe(gulp.dest('src/_attachments/vendor/backbone.modal'));
  gulp.src(['bower_components/backbone-modal/backbone.modal-bundled-min.js']).pipe(gulp.dest('src/_attachments/vendor/backbone.modal'));
  gulp.src(['bower_components/backbone-modal/backbone.modal.css']).pipe(gulp.dest('src/_attachments/vendor/backbone.modal'));
  gulp.src(['bower_components/backbone-modal/backbone.modal.theme.css']).pipe(gulp.dest('src/_attachments/vendor/backbone.modal'));

  // bootstrap
  gulp.src(['bower_components/bootstrap/dist/**/*']).pipe(gulp.dest('src/_attachments/vendor/bootstrap'));

  // font-awesome
  gulp.src(['bower_components/font-awesome/css/**/*']).pipe(gulp.dest('src/_attachments/vendor/font-awesome/css'));
  gulp.src(['bower_components/font-awesome/fonts/**/*']).pipe(gulp.dest('src/_attachments/vendor/font-awesome/fonts'));
})

gulp.task('default', ['compile', 'dependencies']);
