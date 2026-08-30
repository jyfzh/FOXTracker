set_xmakever("2.8.5")
set_project("FOXTracker")
set_version("1.0.0", {description = "Face tracking application for flight simulators"})

set_languages("c++17", "c11")
add_rules("mode.debug", "mode.release")

-- ---------------------------------------------------------------------------
-- External dependencies (downloaded from xrepo)
-- ---------------------------------------------------------------------------
-- `qtbase` downloads the *entire* Qt6 SDK via aqt; the granular `qt6*`
-- packages reuse that SDK and only contribute the correct link names.
--
-- QtCharts has no upstream xrepo package yet, so a local recipe lives under
-- packages/q/qt6charts (reused via the project-local repository below).
add_repositories("local .", {rootdir = os.scriptdir()})
add_requires("qtbase")
add_requires("qt6base")
add_requires("qt6core")
add_requires("qt6gui")
add_requires("qt6widgets")
add_requires("qt6qml")
add_requires("qt6quick")
add_requires("qt6network")
-- QtCharts has no upstream xrepo package yet; it reuses the full Qt6 SDK
-- already pulled in by qt6base (the SDK ships Qt6Charts/Qt6ChartsQml).
add_requires("qt6charts")
add_requires("opencv")

-- Eigen is header-only, so every transitive edge must resolve to the same
-- version. In particular, OpenCV's Eigen feature otherwise selects the latest
-- package independently from Ceres and can leak a different ABI into targets.
add_requires("eigen", {version = "3.4.1"})
add_requireconfs("**.eigen", {version = "3.4.1", override = true})

add_requires("ceres-solver", {configs = {
    suitesparse = false
}})
add_requires("yaml-cpp")
add_requires("dlib")
add_requires("onnxruntime")
add_requires("libusb")
add_requires("libsdl2")

-- ---------------------------------------------------------------------------
-- Local packages (submodules) + in-tree targets
-- ---------------------------------------------------------------------------
includes("lib")

-- Note: the git-submodule libraries are plain targets under lib/ (see
-- includes("lib") above) and are consumed through add_deps(); no local
-- add_requires() is needed for them.

-- ---------------------------------------------------------------------------
-- Main application
-- ---------------------------------------------------------------------------
target("FOXTracker")
    set_kind("binary")
    add_rules("qt.application")   -- moc / uic / rcc + windeployqt + WinMain

    add_files("src/*.cpp")
    add_files("inc/*.h")
    add_files("assets/main.qrc")
    add_values("qt.deploy.qmldir", "assets/qml")

    add_includedirs(".", "inc", "lib")

    add_packages(
        "qtbase",
        "qt6core", "qt6gui", "qt6widgets", "qt6qml", "qt6quick", "qt6network", "qt6charts",
        "opencv", "eigen", "ceres-solver", "yaml-cpp", "dlib", "onnxruntime", "libusb"
    )
    -- QQuickStyle lives in QtQuickControls2 which has no xrepo package; link from the SDK directly
    on_load(function (target)
        -- Qt uses the `d` suffix for Windows debug libraries. Unix Qt builds
        -- keep the same library name for both configurations.
        if is_mode("debug") and is_plat("windows", "mingw") then
            target:add("links", "Qt6QuickControls2d")
        else
            target:add("links", "Qt6QuickControls2")
        end
    end)

    -- In-tree targets and git-submodule libraries (plain targets under lib/).
    add_deps("freetrack", "accela_filter", "ps3eye", "qjoysticks", "uglobalhotkey")

    if is_plat("windows") then
        add_defines(
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
        -- UGlobalHotkey uses the XCB key-symbol API for X11 global hotkeys.
        -- OpenCV's static video I/O target also needs its FFmpeg backends
        -- explicitly on distributions where package metadata omits them.
        add_syslinks(
            "xcb", "xcb-keysyms",
            "avutil", "avcodec", "avformat", "avdevice",
            "swscale", "swresample"
        )
        -- ONNX Runtime is deployed beside the executable below.
        add_rpathdirs("$ORIGIN")
    end

    -- Deploy runtime assets next to the executable.  The application resolves
    -- models and configuration relative to its executable directory on every
    -- platform, so this must happen before platform-specific Qt deployment.
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

        -- Self-contained Qt prefix (plugins/ and qml/ resolved next to the exe).
        local qtconf = path.join(targetdir, "qt.conf")
        io.writefile(qtconf,
            "[Paths]\n" ..
            "Prefix=.\n" ..
            "Plugins=plugins\n" ..
            "Qml2Imports=qml\n")

        import("detect.sdks.find_qt")
        import("lib.detect.find_file")
        import("lib.detect.find_path")
        import("core.base.option")
        import("core.tool.toolchain")
        local qt = find_qt()
        if not qt then
            return
        end
        local search_dirs = {}
        if qt.bindir_host then table.insert(search_dirs, qt.bindir_host) end
        if qt.bindir then table.insert(search_dirs, qt.bindir) end
        local program = find_file("windeployqt.exe", search_dirs)
        if program and os.isexec(program) then
            -- prepare env (mirrors rules/qt/install/windeployqt.lua)
            local envs = nil
            local msvc = toolchain.load("msvc", {plat = target:plat(), arch = target:arch()})
            if msvc then
                local vcvars = msvc:config("vcvars")
                if vcvars and vcvars.VCInstallDir then
                    envs = {VCINSTALLDIR = vcvars.VCInstallDir}
                end
            end
            envs = envs or {}
            envs.PATH = envs.PATH or {}
            if type(envs.PATH) == "string" then envs.PATH = {envs.PATH} end
            if qt.bindir_host then table.insert(envs.PATH, qt.bindir_host) end
            if qt.bindir then table.insert(envs.PATH, qt.bindir) end
            local curpath = os.getenv("PATH")
            if curpath then table.join2(envs.PATH, path.splitenv(curpath)) end

            -- find qml directory for --qmldir (so QtQuick imports are deployed)
            local qmldir = target:values("qt.deploy.qmldir")
            if qmldir then
                qmldir = path.join(target:scriptdir(), qmldir)
            else
                for _, sourcebatch in pairs(target:sourcebatches()) do
                    if sourcebatch.rulename == "qt.qrc" then
                        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                            local dir = path.directory(sourcefile)
                            -- qrc references qml/MainWindow.qml which lives in assets/qml, not directly in assets/
                            -- try dir itself, then dir/qml, and a recursive search as last resort
                            qmldir = find_path("*.qml", dir)
                            if not qmldir then qmldir = find_path("*.qml", path.join(dir, "qml")) end
                            if not qmldir then
                                for _, f in ipairs(os.files(path.join(dir, "**", "*.qml"))) do
                                    qmldir = path.directory(f)
                                    break
                                end
                            end
                            if qmldir then break end
                        end
                    end
                    if qmldir then break end
                end
            end

            local argv = {"--force", "--no-compiler-runtime", "--no-translations"}
            if is_mode("debug") then
                table.insert(argv, "--debug")
            else
                table.insert(argv, "--release")
            end
            if qmldir then
                table.insert(argv, "--qmldir=" .. qmldir)
            end
            local user_flags = table.wrap(target:values("qt.deploy.flags"))
            if #user_flags > 0 then
                argv = table.join(argv, user_flags)
            end
            if option.get("diagnosis") then
                table.insert(argv, "--verbose=2")
            elseif option.get("verbose") then
                table.insert(argv, "--verbose=1")
            else
                table.insert(argv, "--verbose=0")
            end
            table.insert(argv, target:targetfile())
            os.vrunv(program, argv, {envs = envs})

            -- windeployqt deploys plugins next to the exe (targetdir/platforms)
            -- but our qt.conf expects targetdir/plugins/platforms, so mirror it
            -- for both layouts to work (with and without qt.conf).
            local platforms_src = path.join(targetdir, "platforms")
            local platforms_dst = path.join(targetdir, "plugins", "platforms")
            if os.isdir(platforms_src) then
                if not os.isdir(platforms_dst) then
                    os.cp(platforms_src, platforms_dst)
                end
            elseif os.isdir(platforms_dst) then
                -- windeployqt already honored --plugindir? ensure top-level also exists
                if not os.isdir(platforms_src) then
                    os.cp(platforms_dst, platforms_src)
                end
            end
            for _, plugintype in ipairs({"generic", "iconengines", "imageformats", "networkinformation", "qmltooling", "styles", "tls"}) do
                local src = path.join(targetdir, plugintype)
                local dst = path.join(targetdir, "plugins", plugintype)
                if os.isdir(src) and not os.isdir(dst) then
                    os.cp(src, dst)
                elseif os.isdir(dst) and not os.isdir(src) then
                    os.cp(dst, src)
                end
            end
            -- restore qt.conf (windeployqt may touch it when --no-patchqt is not used)
            io.writefile(qtconf,
                "[Paths]\n" ..
                "Prefix=.\n" ..
                "Plugins=plugins\n" ..
                "Qml2Imports=qml\n")
            -- windeployqt sometimes skips QtCharts even with --qmldir if the SDK was initially without charts; ensure it manually
            if qt.qmldir and os.isdir(path.join(qt.qmldir, "QtCharts")) then
                local qc_src = path.join(qt.qmldir, "QtCharts")
                local qc_dst = path.join(targetdir, "qml", "QtCharts")
                if not os.isdir(qc_dst) then os.cp(qc_src, qc_dst) end
                for _, dll in ipairs({"Qt6Charts.dll", "Qt6ChartsQml.dll"}) do
                    local src = path.join(qt.bindir, dll)
                    if os.isfile(src) then os.cp(src, path.join(targetdir, path.filename(src))) end
                end
            end
            return
        end

        -- Fallback: manual copy of the minimal platform plugin set
        -- (when windeployqt is not available).
        if qt.pluginsdir and os.isdir(qt.pluginsdir) then
            local plat_src = path.join(qt.pluginsdir, "platforms")
            if os.isdir(plat_src) then
                os.cp(plat_src, path.join(targetdir, "plugins", "platforms"))
                os.cp(plat_src, path.join(targetdir, "platforms"))
            end
            for _, plugintype in ipairs({"imageformats", "iconengines", "styles"}) do
                local src = path.join(qt.pluginsdir, plugintype)
                if os.isdir(src) then
                    os.cp(src, path.join(targetdir, "plugins", plugintype))
                end
            end
        end
        -- copy Qt runtime DLLs next to the exe (so no PATH needed)
        if qt.bindir and os.isdir(qt.bindir) then
            for _, dll in ipairs(os.files(path.join(qt.bindir, is_mode("debug") and "Qt6*d.dll" or "Qt6*.dll"))) do
                local name = path.filename(dll)
                -- skip debug dlls in release and vice versa (windeployqt would do this, manual fallback keeps it simple)
                if is_mode("debug") or not name:find("d%.dll$") then
                    os.cp(dll, targetdir)
                end
            end
        end
        if qt.qmldir and os.isdir(qt.qmldir) then
            -- copy the QML modules actually imported in qml/ (Controls is required for MainWindow.qml, Charts for EkfPage)
            for _, mod in ipairs({"QtQuick", "QtQml", "Qt", "QtCharts"}) do
                local src = path.join(qt.qmldir, mod)
                if os.isdir(src) then os.cp(src, path.join(targetdir, "qml", mod)) end
            end
        end

    end)
