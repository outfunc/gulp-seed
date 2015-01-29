gulp = require("gulp")
$ = require("gulp-load-plugins")(
  pattern: [
    "gulp-*"
    "gulp.*"
  ]
  replaceString: /\bgulp[\-.]/
)
runSequence = require("run-sequence")
browserSync = require("browser-sync")
mainBowerFiles = require("main-bower-files")
browserify = require("browserify")
debowerify = require("debowerify")
vinylsource = require("vinyl-source-stream")
streamify = require("gulp-streamify")
rimraf = require("rimraf")
del = require("del")
gulpif = require("gulp-if")
isInit = false

# $.jadePhp( $.jade );
paths =
    tplSrc: [
        "app/**/*.jade"
        "!app/template/**/*.jade"
        "!app/**/_*.jade"
    ]
    lessSrc: "app/assets/less/*.less"
    scssSrc: "app/assets/scss/**/*.scss"
    jsSrc: "app/assets/js/*.js"
    coffeeSrc: "app/assets/js/*.coffee"
    imgSrc: "app/assets/imgs/**"
    rootDir: "dist/"
    assetsDir: "dist/assets/"
    imgDir: "dist/assets/imgs/"

gulp.task "bs", ->
    browserSync.init null,
        server:
          baseDir: "dist/"

        notify: true
        xip: false

    return


# browserSync.init( null, {
#   proxy : 'http://jtr.nude'
# });
gulp.task "require", ->
    browserify(
        entries: ["./app/assets/js/require.js"]
        transform: ["debowerify"]
    )
    .bundle()
    .pipe(vinylsource("plugins.js"))
    .pipe(streamify($.uglify()))
    .pipe gulp.dest("./dist/assets/js/")
    return

gulp.task "sprite", ->
    spriteData =
        gulp
            .src("app/assets/imgs/common/sprite/*.png")
            .pipe($.spritesmith(
                imgName: "sprite.png" #スプライトの画像
                cssName: "_sprite.scss" #生成されるscss
                imgPath: "../imgs/sprite/sprite.png" #生成されるscssに記載されるパス
                cssFormat: "scss" #フォーマット
                padding: 10
                algorithm: "binary-tree"
                cssVarMap: (sprite) ->
                    sprite.name = "sprite-" + sprite.name #VarMap(生成されるScssにいろいろな変数の一覧を生成)
                    return
              ))
      spriteData.img.pipe gulp.dest("app/assets/imgs/sprite") #imgNameで指定したスプライト画像の保存先
      spriteData.css.pipe gulp.dest("app/assets/scss/") #cssNameで指定したcssの保存先
      return

gulp.task "bower", ->
    filter = $.filter("**/*css")
    jsFilter = $.filter("**/*js")
    gulp
        .src(mainBowerFiles(),
            base: "bower_components"
        )
        .pipe(filter)
        .pipe($.flatten())
        .pipe(filter.restore())
        .pipe(jsFilter)
        .pipe($.flatten())
        .pipe(jsFilter.restore())
        .pipe gulp.dest("dist/common/lib")


hadError = (err) ->
    str = ""
    str += "=================================\nError:\n"
    str += err
    str +=  "\n=================================\n"
    return str



gulp.task "html", ->
    # If you need prettify HTML, uncomment below 2 lines.
    # .pipe($.prettify())
    gulp
        .src(paths.tplSrc)
        .pipe($.plumber(errorHandler: (err) ->
            console.log hadError( err.path )
        ))
        .pipe( $.data((file) ->
            require "./app/config.json"
        ))
        .pipe( gulpif(isInit, $.changed("dist", extension: ".html")))
        .pipe( $.jade(pretty: true) )
        .pipe( gulp.dest(paths.rootDir) )
        .pipe( browserSync.reload(stream: true) )



gulp.task "scss", ->
    # quiet : true,  // warningを非表示にする
    # .on('error', console.error.bind(console))
    # .pipe($.autoprefixer('last 2 version'))
    # .pipe($.csso())
    gulp
        .src(paths.scssSrc)
        .pipe($.plumber(errorHandler: $.notify.onError("<%= error.message %>")))
        .pipe($.rubySass(
            loadPath: ["bower_components/foundation/scss"]
            style: "expanded"
            "sourcemap=none": true
        ))
        .pipe($.autoprefixer("last 2 version", "safari 5", "ie 8", "ie 9", "opera 12.1", "ios 6", "android 4"))
        .pipe($.notify(
            message: "css: <%= file.relative %> @ <%= options.date %>"
            templateOptions:
                date: new Date()
        ))
        .pipe(gulp.dest(paths.assetsDir + "css"))
        .pipe browserSync.reload(
            stream: true
            once: true
            )

gulp.task "css_min", ->
    gulp
        .src("dist/assets/css/*")
        .pipe($.csscomb())
        .pipe($.csso())
        .pipe(gulp.dest(paths.assetsDir + "css"))
        .pipe $.notify( #実行中にエラーがでたらデスクトップに通知する
            message: "cssmin: <%= file.relative %> @ <%= options.date %>"
            templateOptions:
                date: new Date()
            )


gulp.task "coffee", ->
    gulp
        .src(paths.coffeeSrc)
        .pipe($.plumber(errorHandler: (err) ->
                throw hadError( err.location )
            ))
        .pipe($.coffee())
        .pipe(gulp.dest(paths.assetsDir + "js"))


gulp.task "scripts", ->
    # .pipe($.sourcemaps.init())
    #   .pipe($.uglify())
    #  .pipe($.concat('all.js'))
    # .pipe($.sourcemaps.write())
    gulp
        .src(paths.jsSrc)
        .pipe gulp.dest(paths.assetsDir + "js")

gulp.task "image", ->
    # See gulp-imagemin page.
    gulp
        .src(paths.imgSrc)
        .pipe($.newer(paths.imgDir))
        .pipe($.imagemin(optimizationLevel: 3))
        .pipe gulp.dest(paths.imgDir)


# Sequential tasks demo. Try to run 'npm run-script gulpbuild' or 'gulp build'.
gulp.task "build", ->
    runSequence "image", "html", [ # less and scripts task in parallel.
        "less"
        "scripts"
    ]
    return

gulp.task "clean", del.bind(null, ["dist/assets/css"])
gulp.task "watch", ->
    gulp.watch [paths.tplSrc], ["html"]
    gulp.watch ["app/assets/imgs/**/sprite/*.png"], ["sprite"]
    gulp.watch [paths.scssSrc], ["scss"]
    gulp.watch [paths.jsSrc], ["scripts"]
    gulp.watch [paths.coffeeSrc], ["coffee"]
    gulp.watch [paths.imgSrc], ["image"]
    return

gulp.task "default", [
    "image"
    "bs"
    "coffee"
    "scss"
    "html"
    "watch"
    ], ->
        console.log "complete gulp initialized"
        isInit = true
        return


# Sequential tasks demo. Try to run 'npm run-script gulpbuild' or 'gulp build'.
gulp.task "baseinit", ->
    runSequence "clean-all", "bower", "require"
    return


# ['less', 'scripts'] // less and scripts task in parallel.
gulp.task "clean", del.bind(null, ["dist/assets/css"])
gulp.task "clean-all", del.bind(null, ["dist"])