gulp = require("gulp")
$ = require("gulp-load-plugins")(
  pattern: [
    "gulp-*"
    "gulp.*"
  ]
  replaceString: /\bgulp[\-.]/
)
runSequence     = require("run-sequence")
browserSync     = require("browser-sync")
mainBowerFiles  = require("main-bower-files")
browserify      = require("browserify")
debowerify      = require("debowerify")
vinylsource     = require("vinyl-source-stream")
streamify       = require("gulp-streamify")
rimraf          = require("rimraf")
del             = require("del")
gulpif          = require("gulp-if")
# iconv         = require("gulp-iconv")
isInit          = false

# $.jadePhp( $.jade );

# ==========================================================
#   initial settings
# ==========================================================
root    = "dist/"
path    =
    src:
        jade: [
            "app/**/*.jade"
            "!app/template/**/*.jade"
            "!app/**/_*.jade"
        ]
        html: [
            "app/**/*.html"
            "!app/template/**/*.html"
            "!app/**/_*.html"
        ]
        less: "app/assets/less/**/*.less"
        scss: "app/assets/scss/**/*.scss"
        js: "app/assets/js/*.js"
        coffee: "app/assets/js/*.coffee"
        img : "app/assets/imgs/**"
    dst:
        root: root
        assets: root + "assets/"
        img: root + "assets/imgs/"

hadError = (err) ->
    str = ""
    str += "=================================\nError:\n"
    str += err
    str +=  "\n=================================\n"
    return str

# ==========================================================
#   browserSync
# ==========================================================

gulp.task "bs", ->
    root = "dist/"
    browserSync
        server:
            baseDir: root
        #   proxy : 'http://kntip.kn'

        notify: true
        xip: false
    return




# ==========================================================
#   require
# ==========================================================

gulp.task "require", ->
    browserify(
        entries: ["./app/assets/js/require.js"]
        transform: ["debowerify"]
    )
    .bundle()
    .pipe(vinylsource("plugins.js"))
    # .pipe(streamify($.uglify()))
    .pipe gulp.dest("./dist/assets/js/")
    return

# ==========================================================
#   sprite images
# ==========================================================

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




# ==========================================================
#   relocation bower files
# ==========================================================

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




# ==========================================================
#   JADE to HTML
# ==========================================================

gulp.task "jade", ->
    # If you need prettify HTML, uncomment below 2 lines.
    # .pipe($.prettify())
    gulp
        .src(path.src.jade)
        .pipe($.plumber(errorHandler: (err) ->
            console.log hadError( err.path )
        ))
        .pipe( $.data((file) ->
            require "./app/config.json"
        ))
        .pipe( gulpif(isInit, $.changed("dist", extension: ".html")))
        .pipe( $.jade(pretty: true) )
        # .pipe( $.iconv({decoding:"utf-8", encoding:"shift_jis"}))
        .pipe( gulp.dest(path.dst.root) )
        .pipe( browserSync.reload(stream: true) )


# ==========================================================
#   EXTEND HTML
# ==========================================================

gulp.task "html", ->
    gulp
        .src(path.src.html)
        .pipe($.plumber(errorHandler: (err) ->
            console.log hadError( err )
        ))
        .pipe( gulpif(isInit, $.changed("dist", extension: ".html")))
        .pipe( $.fileInclude() )
        # shift_jisへ変換する場合はコメントアウト
        .pipe( $.iconv({decoding:"utf-8", encoding:"shift_jis"}))
        .pipe( gulp.dest(path.dst.root) )
        .pipe( browserSync.reload(stream: true) )




# ==========================================================
#   Convert CSS
# ==========================================================

gulp.task "scss", ->
    # quiet : true,  // warningを非表示にする
    # .on('error', console.error.bind(console))
    # .pipe($.autoprefixer('last 2 version'))
    # .pipe($.csso())
    gulp
        .src(path.src.scss)
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
        .pipe(gulp.dest(path.dst.assets + "css"))
        .pipe browserSync.reload(
            stream: true
            once: true
            )


# ==========================================================
#   Minify CSS
# ==========================================================

gulp.task "css_min", ->
    gulp
        .src("dist/assets/css/*")
        .pipe($.csscomb())
        .pipe($.csso())
        .pipe(gulp.dest(path.dst.assets + "css"))
        .pipe $.notify( #実行中にエラーがでたらデスクトップに通知する
            message: "cssmin: <%= file.relative %> @ <%= options.date %>"
            templateOptions:
                date: new Date()
            )


# ==========================================================
#   Coffee to Javascript
# ==========================================================

gulp.task "coffee", ->
    gulp
        .src(path.src.coffee)
        .pipe($.plumber(errorHandler: (err) ->
                # throw hadError( err.location )
                console.log hadError( err )
            ))
        .pipe($.coffee())
        .pipe(gulp.dest(path.dst.assets + "js"))


gulp.task "scripts", ->
    # .pipe($.sourcemaps.init())
    #   .pipe($.uglify())
    #  .pipe($.concat('all.js'))
    # .pipe($.sourcemaps.write())
    gulp
        .src(path.src.js)
        .pipe gulp.dest(path.dst.assets + "js")


# ==========================================================
#   Oprimization Images
# ==========================================================

gulp.task "image", ->
    # See gulp-imagemin page.
    gulp
        .src(path.src.img)
        .pipe($.newer(path.dst.img))
        .pipe($.imagemin(optimizationLevel: 3))
        .pipe gulp.dest(path.dst.img)


# ==========================================================
#   Build task
# ==========================================================

# Sequential tasks demo. Try to run 'npm run-script gulpbuild' or 'gulp build'.
gulp.task "build", ->
    runSequence "image", "jade", [ # less and scripts task in parallel.
        "less"
        "scripts"
    ]
    return

gulp.task "clean", del.bind(null, ["dist/assets/css"])
gulp.task "watch", ->
    gulp.watch [path.src.jade], ["jade"]
    # gulp.watch [path.src.html], ["html"]
    gulp.watch ["app/assets/imgs/**/sprite/*.png"], ["sprite"]
    gulp.watch [path.src.scss], ["scss"]
    gulp.watch [path.src.js], ["scripts"]
    gulp.watch [path.src.coffee], ["coffee"]
    gulp.watch [path.src.img], ["image"]
    return

gulp.task "default", [
    "image"
    "bs"
    "coffee"
    "scss"
    "jade"
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