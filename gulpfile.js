var gulp = require('gulp'),
    $ = require('gulp-load-plugins')({
        pattern: ['gulp-*', 'gulp.*'],
        replaceString: /\bgulp[\-.]/
    }),
    runSequence = require('run-sequence'),
    browserSync = require('browser-sync'),
    mainBowerFiles = require('main-bower-files'),
    browserify = require("browserify"),
    debowerify = require("debowerify"),
    vinylsource = require('vinyl-source-stream'),
    streamify = require('gulp-streamify'),
    rimraf = require('rimraf'),
    del = require('del'),
    gulpif = require('gulp-if');

var isInit = false;
// $.jadePhp( $.jade );

var paths = {
    "tplSrc": ["app/**/*.jade", "!app/template/**/*.jade"],
    "lessSrc": "app/assets/less/*.less",
    "scssSrc": "app/assets/scss/**/*.scss",
    "jsSrc": "app/assets/js/*.js",
    "imgSrc": "app/assets/imgs/**",
    "rootDir": "dist/",
    "assetsDir": "dist/assets/",
    "imgDir": "dist/assets/imgs/"
}

gulp.task('bs', function() {
    browserSync.init(null, {
        server: {
            baseDir: 'dist/'
        },
        notify: true,
        xip: false
    });
    // browserSync.init( null, {
    //   proxy : 'http://jtr.nude'
    // });
});

gulp.task('require', function() {
    browserify({
            entries: ['./app/assets/js/require.js'],
            transform: ['debowerify']
        })
        .bundle()
        .pipe(vinylsource('plugins.js'))
        .pipe(streamify($.uglify()))
        .pipe(gulp.dest("./dist/assets/js/"));
});


gulp.task('sprite', function() {
    var spriteData = gulp.src('app/assets/imgs/common/sprite/*.png')
        .pipe($.spritesmith({
            imgName: 'sprite.png', //スプライトの画像
            cssName: '_sprite.scss', //生成されるscss
            imgPath: '../imgs/sprite/sprite.png', //生成されるscssに記載されるパス
            cssFormat: 'scss', //フォーマット
            padding: 10,
            algorithm: 'binary-tree',
            cssVarMap: function(sprite) {
                sprite.name = 'sprite-' + sprite.name; //VarMap(生成されるScssにいろいろな変数の一覧を生成)
            }
        }));
    spriteData.img.pipe(gulp.dest('app/assets/imgs/sprite')); //imgNameで指定したスプライト画像の保存先
    spriteData.css.pipe(gulp.dest('app/assets/scss/')); //cssNameで指定したcssの保存先
});


gulp.task('bower', function() {
    var filter = $.filter('**/*css');
    var jsFilter = $.filter('**/*js');

    return gulp
        .src(mainBowerFiles(), {
            base: 'bower_components'
        })
        .pipe(filter)
        .pipe($.flatten())
        .pipe(filter.restore())
        .pipe(jsFilter)
        .pipe($.flatten())
        .pipe(jsFilter.restore())
        .pipe(gulp.dest('dist/common/lib'));
});

gulp.task('html', function() {
    return gulp.src(paths.tplSrc)
        .pipe($.data(function(file) {
            return require('./app/config.json')
        }))
        .pipe(gulpif(isInit, $.changed('dist', {
            extension: '.html'
        })))
        .pipe($.jade({
            pretty: true
        }))
        .on('error', console.error.bind(console))
        .pipe(gulp.dest(paths.rootDir))
        // If you need prettify HTML, uncomment below 2 lines.
        // .pipe($.prettify())
        .pipe(gulp.dest('dist'))
        .pipe(browserSync.reload({
            stream: true
        }));
});

// gulp.task('less', function() {
//     return gulp.src(paths.lessSrc)
//         .pipe($.sourcemaps.init())
//         .pipe($.less())
//         .pipe($.autoprefixer('last 2 version'))
//         .pipe($.sourcemaps.write())
//         .pipe(gulp.dest(paths.assetsDir + 'css'))
//         .pipe($.rename({
//             suffix: '.min'
//         }))
//         .pipe($.csso())
//         .pipe(gulp.dest(paths.assetsDir + 'css'))
//         .pipe(browserSync.reload({
//             stream: true,
//             once: true
//         }));
// });

gulp.task('scss', function() {
    return gulp.src(paths.scssSrc)
        .pipe($.plumber({
            errorHandler: $.notify.onError('<%= error.message %>')
        }))
        .pipe($.rubySass({
            loadPath: ['bower_components/foundation/scss'],
            style: 'expanded',
            // quiet : true,  // warningを非表示にする
            "sourcemap=none": true
        }))
        // .on('error', console.error.bind(console))
        // .pipe($.autoprefixer('last 2 version'))
        .pipe($.autoprefixer('last 2 version', 'safari 5', 'ie 8', 'ie 9', 'opera 12.1', 'ios 6', 'android 4'))
        // .pipe($.csso())
        .pipe($.notify({
            message: "css: <%= file.relative %> @ <%= options.date %>",
            templateOptions: {
                date: new Date()
            }
        }))
        .pipe(gulp.dest(paths.assetsDir + 'css'))
        .pipe(browserSync.reload({
            stream: true,
            once: true
        }));
});

gulp.task('css_min', function() {
    return gulp.src('dist/assets/css/*')
        .pipe($.csscomb())
        .pipe($.csso())
        .pipe(gulp.dest(paths.assetsDir + 'css'))
        .pipe($.notify({ //実行中にエラーがでたらデスクトップに通知する
            message: "cssmin: <%= file.relative %> @ <%= options.date %>",
            templateOptions: {
                date: new Date()
            }
        }))
});

gulp.task('scripts', function() {
    return gulp.src(paths.jsSrc)
        // .pipe($.sourcemaps.init())
        //   .pipe($.uglify())
        //  .pipe($.concat('all.js'))
        // .pipe($.sourcemaps.write())
        .pipe(gulp.dest(paths.assetsDir + 'js'));
});


gulp.task('image', function() {
    return gulp.src(paths.imgSrc)
        .pipe($.newer(paths.imgDir))
        .pipe($.imagemin({
            optimizationLevel: 3
        })) // See gulp-imagemin page.
        .pipe(gulp.dest(paths.imgDir));
});


// Sequential tasks demo. Try to run 'npm run-script gulpbuild' or 'gulp build'.
gulp.task('build', function() {
    runSequence(
        'image',
        'html', ['less', 'scripts'] // less and scripts task in parallel.
    );
});
gulp.task('clean', del.bind(null, ['dist/assets/css']));


gulp.task('watch', function() {
    gulp.watch([paths.tplSrc], ['html']);
    // gulp.watch([paths.lessSrc], ['less']);
    gulp.watch(['app/assets/imgs/**/sprite/*.png'], ['sprite']);
    gulp.watch([paths.scssSrc], ['scss']);
    gulp.watch([paths.jsSrc], ['scripts']);
    gulp.watch([paths.imgSrc], ['image']);
});

gulp.task('default', ['image', 'bs', 'scripts', 'scss', 'html', 'watch'], function(){
  console.log("complete gulp initialized");
  isInit = true;
});



// Sequential tasks demo. Try to run 'npm run-script gulpbuild' or 'gulp build'.
gulp.task('baseinit', function() {
    runSequence(
        'clean-all',
        'bower',
        'require'
        // ['less', 'scripts'] // less and scripts task in parallel.
    );
});

gulp.task('clean', del.bind(null, ['dist/assets/css']));
gulp.task('clean-all', del.bind(null, ['dist']));
