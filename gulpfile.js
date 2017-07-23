var gulp = require('gulp'),
    plugins = require('gulp-load-plugins')(),
    htmlbuild = require('gulp-htmlbuild'),
    es = require('event-stream'),
    less = require('gulp-less'),
    path = require('path'),
    replace = require('gulp-replace'),
    gulpSequence = require('gulp-sequence'),
    webserver = require('gulp-webserver'),
    jshint = require('gulp-jshint'),
    stylish = require('jshint-stylish'),
    watch = require('gulp-watch'),
    request = require('request'),
    clean = require('gulp-clean'),
    uglify = require('gulp-uglify'),
    concat = require('gulp-concat'),
    cssmin = require('gulp-cssmin'),
    livereload = require('gulp-livereload'),
    moment = require('moment');

// https://www.npmjs.com/package/gulp-webserver
gulp.task('serve', ['watch'], function() {
    gulp.src('')
        .pipe(webserver({
            livereload: {
                enable: false,
                filter: function(fileName) {
                    // exclude all source maps from livereload
                    if (fileName.match(/LICENSE|\.json$|\.md|lib|backend|node_modules|build|pdf-viewer/)) {
                        return false;
                    } else {
                        return true;
                    }
                }
            },
            directoryListing: false,
            open: false,
            port: 9000
        }));
});

gulp.task('livereload', function() {
    gulp.src('src')
        .pipe(livereload());
});

gulp.task('watch', function() {
    livereload.listen();
    gulp.watch([
        'src/*.html',
        'src/*.js',
        'src/*.less',
        'src/*.css',
        'src/directive/**/*.*',
        'src/partial/**/*.*',
        'src/service/**/*.*',
        'src/constant/**/*.*',
        'src/filter/**/*.*'
    ], { cwd: './' }, ['livereload']);
    gulp.watch('src/*.js', { cwd: './' }, ['jshint']);
    gulp.watch('src/directive/**/*.js', { cwd: './' }, ['jshint']);
    gulp.watch('src/partial/**/*.js', { cwd: './' }, ['jshint']);
    gulp.watch('src/service/**/*.js', { cwd: './' }, ['jshint']);
    gulp.watch('src/constant/**/*.js', { cwd: './' }, ['jshint']);
    gulp.watch('src/filter/**/*.js', { cwd: './' }, ['jshint']);
    gulp.watch('backend/cf/**/*.*', { cwd: './' }, ['rest-cf-init']);
});

var requestCount = 0;
gulp.task('rest-cf-init', function() {
    var url = 'http://localhost:8500/gas/backend/cf/rest-init.cfm'
    request(url, function(error, response, body) {
        if (!error && response.statusCode == 200) {
            console.log('[' + moment().format('HH:mm:ss') + ']', body);
            requestCount = 0;
        } else if (response.statusCode === 500 && requestCount < 3) {
            requestCount++;
            console.log('[' + moment().format('HH:mm:ss') + ']', 'Fail(' + requestCount + ')  \'rest-cf-init\' try again...');
            setTimeout(function() {
                gulp.start('rest-cf-init');
            }, 3000);

        } else if (response.statusCode === 500) {
            console.log('[' + moment().format('HH:mm:ss') + ']', 'Fail(' + requestCount + ')  \'rest-cf-init\' try to access by browser please: ' + url);
            requestCount = 0;
        }
    });
});

gulp.task('jshint', function() {
    return gulp
        .src(['./src/*.js',
            './src/directive/**/*.js',
            './src/partial/**/*.js',
            './src/service/**/*.js',
            './src/constant/**/*.js',
            './src/filter/**/*.js'
        ])
        .pipe(jshint())
        .pipe(jshint.reporter('jshint-stylish'));
});


// pipe a glob stream into this and receive a gulp file stream 
var gulpSrc = function(opts) {
    var paths = es.through();
    var files = es.through();

    paths.pipe(es.writeArray(function(err, srcs) {

        for (var i = 0; i <= srcs.length - 1; i++) {
            srcs[i] = 'src/' + srcs[i];
        }

        gulp.src(srcs, opts).pipe(files);
    }));

    return es.duplex(paths, files);
};


var jsBuild = es.pipeline(
    uglify(),
    plugins.concat('concat.js'),
    gulp.dest('./src/build/js')
);

var cssBuild = es.pipeline(
    plugins.concat('concat.css'),
    gulp.dest('./src/build/css')
);


gulp.task('htmlbuild', function() {

    gulp.src(['./src/index.html'])
        .pipe(htmlbuild({
            // build js with preprocessor 
            js: htmlbuild.preprocess.js(function(block) {

                block.pipe(gulpSrc())
                    .pipe(jsBuild);

                block.end('js/concat.js');

            }),

            // build css with preprocessor 
            css: htmlbuild.preprocess.css(function(block) {

                block.pipe(gulpSrc())
                    .pipe(cssBuild);

                block.end('css/concat.css');

            }),

            // remove blocks with this target 
            remove: function(block) {
                block.end();
            },

            // add a template with this target 
            template: function(block) {
                es.readArray([
                    '<!--',
                    '  processed by htmlbuild (' + block.args[0] + ')',
                    '-->'
                ].map(function(str) {
                    return block.indent + str;
                })).pipe(block);
            }
        }))
        .pipe(gulp.dest('./src/build'));
});

gulp.task('less', function() {
    return gulp.src('./src/app.less')
        .pipe(less({
            paths: [path.join(__dirname, 'less', 'includes')]
        }))
        //.pipe(cssmin())
        .pipe(gulp.dest('./src/build'));
});

gulp.task('material-css', function() {
    return gulp.src('./src/lib/angular-material/angular-material.min.css')
        .pipe(gulp.dest('./src/build/lib/angular-material/'));
});

gulp.task('partial-html', function() {
    return gulp.src('./src/partial/**/*.html')
        .pipe(gulp.dest('./src/build/partial/'));
});

gulp.task('assets', function() {
    return gulp
        .src(['./src/assets/**/*.jpg',
            './src/assets/**/*.png',
            './src/assets/**/*.gif'
        ])
        .pipe(gulp.dest('./src/build/assets/'));
});

gulp.task('lib-fonts', function() {
    return gulp
        .src(['./src/lib/**/*.ttf',
            './src/lib/**/*.woff',
            './src/lib/**/*.woff2'
        ])
        .pipe(gulp.dest('./src/build/lib/'));
});

gulp.task('pdf-viewer', function() {
    return gulp
        .src('./src/pdf-viewer/**')
        .pipe(gulp.dest('./src/build/pdf-viewer'));
});

gulp.task('index-replace', function() {
    gulp.src(['./src/build/index.html'])
        .pipe(replace('app.less', 'app.css'))
        .pipe(replace('stylesheet/less', 'stylesheet'))
        .pipe(gulp.dest('./src/build'));
})

gulp.task('js-compress', function() {
    return gulp
        .src(['!./src/build/js/*.min.js', './src/build/js/*.js'])
        .pipe(uglify())
        .pipe(gulp.dest('./src/build/js/'));
});

gulp.task('js-concat', function() {
    return gulp
        .src(['./src/build/js/*.js'])
        .pipe(concat('concat.js'))
        .pipe(gulp.dest('./src/build/js/'));
});

gulp.task('js-clean', function() {
    return gulp
        .src(['!./src/build/js/concat.js',
            './src/build/js/*.js'
        ])
        .pipe(clean({ force: true }));
});

gulp.task('backend-cf', function() {
    return gulp
        .src(['./backend/cf/**/*.cfm',
            './backend/cf/**/*.cfc'
        ])
        .pipe(gulp.dest('./src/build/backend/cf'));
});

gulp.task('clean', function() {
    return gulp.src('./src/build')
        .pipe(clean({ force: true }));
});

gulp.task('default', ['build']);

gulp.task('build', function() {
    gulpSequence('clean',
        'htmlbuild',
        'less',
        'material-css',
        'partial-html',
        'assets',
        'lib-fonts',
        //'js-compress',
        //'js-concat',
        //'js-clean',
        'pdf-viewer',
        'index-replace',
        'backend-cf')();
});

gulp.task('build-backend-cf', function() {
    projectBuild = 'main';
    gulpSequence('clean',
        'backend-cf')();
});