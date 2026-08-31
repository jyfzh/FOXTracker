set_xmakever("2.8.5")
set_project("FOXTracker")
set_version("1.0.0", {description = "Face tracking application for flight simulators"})

set_languages("c++17", "c11")
add_rules("mode.debug", "mode.release")

add_repositories("local .", {rootdir = os.scriptdir()})
add_requires("qtbase")
add_requires("qt6base")
add_requires("qt6core")
add_requires("qt6gui")
add_requires("qt6widgets")
add_requires("qt6qml")
add_requires("qt6quick")
add_requires("qt6network")
add_requires("qt6charts")
add_requires("qt6quickcontrols2")
add_requires("opencv")

add_requires("eigen", {version = "3.4.1"})
add_requireconfs("**.eigen", {version = "3.4.1", override = true})

add_requires("ceres-solver", {configs = { suitesparse = false }})
add_requires("yaml-cpp")
add_requires("dlib")
add_requires("onnxruntime")
add_requires("libusb")
add_requires("libsdl2")

includes("lib")

target("FOXTracker")
    add_rules("qt.application")

    add_includedirs("src")
    add_files("src/*.cpp", "src/accela_filter/*.cpp")
    add_files("src/*.h")
    add_files("assets/main.qrc")
    add_values("qt.deploy.qmldir", "assets/qml")
    add_values("qt.deploy.flags",
        "--no-compiler-runtime",
        "--no-translations",
        is_mode("debug") and "--debug" or "--release")

    add_packages(
        "qtbase", "qt6core", "qt6gui", "qt6widgets", "qt6qml", "qt6quick", "qt6network", "qt6charts", "qt6quickcontrols2",
        "opencv", "eigen", "ceres-solver", "yaml-cpp", "dlib", "onnxruntime", "libusb"
    )

    add_deps("freetrack", "ps3eye", "qjoysticks", "uglobalhotkey")

    if is_plat("windows") then
        add_defines(
            "_CRT_SECURE_NO_WARNINGS",
            "_USE_MATH_DEFINES",
            "_MBCS",
            "CERES_MSVC_USE_UNDERSCORE_PREFIXED_BESSEL_FUNCTIONS",
            "GOOGLE_GLOG_DLL_DECL=",
            "NOMINMAX",
            "SDL_MAIN_HANDLED"
        )
        add_cxflags("/W3", "/utf-8")
        set_encodings("utf-8")
        add_syslinks("dwmapi")
    elseif is_plat("linux") then
        add_syslinks(
            "xcb", "xcb-keysyms",
            "avutil", "avcodec", "avformat", "avdevice",
            "swscale", "swresample"
        )
        -- ONNX Runtime is deployed beside the executable below.
        add_rpathdirs("$ORIGIN")
    end

    after_build(function (target)
        local targetdir = target:targetdir()
        os.cp(path.join(os.projectdir(), "assets"), targetdir)

        -- Seed config.yaml from the template, but never overwrite a saved one.
        local cfgdst = path.join(targetdir, "assets", "config.yaml")
        local cfgsrc = path.join(os.projectdir(), "assets", "config.template.yaml")
        if not os.isfile(cfgdst) and os.isfile(cfgsrc) then
            os.cp(cfgsrc, cfgdst)
        end

        local function deploy_onnxruntime()
            local ort_pkg = target:pkg("onnxruntime")
            if not ort_pkg then
                return
            end

            local installdir = ort_pkg:installdir()
            if not installdir then
                return
            end

            local patterns
            if is_plat("windows") then
                patterns = {
                    "*.dll",
                    "bin/*.dll",
                    "lib/*.dll",
                }
            elseif is_plat("linux") then
                patterns = {
                    "lib/libonnxruntime.so*",
                    "lib/libonnxruntime_providers_shared.so*",
                }
            elseif is_plat("macosx") then
                patterns = {"lib/libonnxruntime*.dylib*"}
            end

            if not patterns then
                return
            end

            for _, pattern in ipairs(patterns) do
                for _, runtime_file in ipairs(os.files(path.join(installdir, pattern))) do
                    -- Always replace an existing copy: incremental builds must
                    -- not retain an older runtime from a previous package.
                    os.cp(runtime_file, targetdir)
                end
            end
        end
        deploy_onnxruntime()
        if not is_plat("windows") then
            return
        end

        -- Keep Qt's runtime paths next to the executable.
        local qtconf = path.join(targetdir, "qt.conf")
        local function write_qtconf()
            io.writefile(qtconf,
                "[Paths]\n" ..
                "Prefix=.\n" ..
                "Plugins=plugins\n" ..
                "Qml2Imports=qml\n")
        end
        write_qtconf()

        -- Reuse Xmake's Qt deployment implementation instead of duplicating
        -- Qt discovery, toolchain environment, and windeployqt arguments.
        import("rules.qt.install.windeployqt", {rootdir = os.programdir()})
        windeployqt.run_deploy(target, targetdir, {target:targetfile()})
        write_qtconf()

        -- windeployqt may put plugins beside the executable. Mirror those
        -- directories under the path declared in qt.conf.
        for _, plugintype in ipairs({
            "platforms", "generic", "iconengines", "imageformats",
            "networkinformation", "qmltooling", "styles", "tls"
        }) do
            local src = path.join(targetdir, plugintype)
            local dst = path.join(targetdir, "plugins", plugintype)
            if os.isdir(src) and not os.isdir(dst) then
                os.cp(src, dst)
            end
        end
    end)
