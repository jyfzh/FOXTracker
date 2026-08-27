-- Local Qt6Charts package.
--
-- xmake-repo ships a prebuilt `qt6base` SDK that does NOT include the QtCharts
-- addon, so the upstream granular `qt6charts` package (which merely reuses that
-- SDK) fails to link `Qt6Charts.lib`.  This local recipe fixes that by fetching
-- the `qtcharts` module with aqt and merging it into the *shared* qt6base SDK
-- directory.  Merging (instead of installing into a separate prefix) is
-- deliberate: the rest of the qt6* packages, `find_qt()`, and `windeployqt`
-- already resolve headers/libs/DLLs from that one SDK tree, so Charts becomes
-- available everywhere with no further wiring.
package("qt6charts")
    set_kind("library")
    set_homepage("https://www.qt.io")
    set_description("Qt 6 Charts addon module")
    set_license("LGPL-3")

    -- Sync with qt6base / qt6lib version list.
    add_versions("6.3.0", "dummy")
    add_versions("6.3.1", "dummy")
    add_versions("6.3.2", "dummy")
    add_versions("6.4.0", "dummy")
    add_versions("6.4.1", "dummy")
    add_versions("6.4.2", "dummy")
    add_versions("6.4.3", "dummy")
    add_versions("6.5.0", "dummy")
    add_versions("6.5.1", "dummy")
    add_versions("6.5.2", "dummy")
    add_versions("6.5.3", "dummy")
    add_versions("6.6.0", "dummy")
    add_versions("6.6.1", "dummy")
    add_versions("6.6.2", "dummy")
    add_versions("6.6.3", "dummy")
    add_versions("6.7.0", "dummy")
    add_versions("6.7.1", "dummy")
    add_versions("6.7.2", "dummy")
    add_versions("6.8.0", "dummy")
    add_versions("6.8.1", "dummy")
    add_versions("6.8.2", "dummy")
    add_versions("6.8.3", "dummy")
    add_versions("6.9.0", "dummy")
    add_versions("6.9.1", "dummy")

    on_load(function (package)
        -- Anchor to the same Qt version/arch the rest of the SDK uses, and pull
        -- in aqt so the charts addon can be downloaded during install.
        package:add("deps", "qt6base", {debug = package:is_debug(), version = package:version_str()})
        package:add("deps", "aqt")
        -- Keep the standard module dependency chain satisfied.
        package:add("deps", "qt6core", "qt6gui", "qt6widgets", "qt6qml", "qt6quick", {debug = package:is_debug(), version = package:version_str()})
        package:data_set("libname", "Charts")

        if package:is_plat("iphoneos") then
            package:data_set("frameworks", {"QtCharts"})
        end
    end)

    on_install(function (package)
        import("core.base.semver")

        -- Locate the shared SDK directory owned by qt6base.
        local qtbase = package:dep("qt6base")
        local sdkdir = qtbase and qtbase:installdir()
        if not sdkdir or not os.isdir(sdkdir) then
            sdkdir = package:installdir()
        end

        -- Already merged? Skip the (slow) aqt download.
        if os.isfile(path.join(sdkdir, "lib", "Qt6Charts.lib")) or
           os.isfile(path.join(sdkdir, "lib", "Qt6Chartsd.lib")) then
            return
        end

        local versionstr = package:version():shortstr()

        -- Resolve the <host>/<arch> tuple aqt expects (aqt 3.x names MSVC
        -- architectures as e.g. "msvc2022_64").
        local pseudo_host = "windows"
        local arch = "msvc2022_64"
        local msvc = package:toolchain("msvc")
        if msvc then
            local vs = tonumber(msvc:config("vs") or "2022")
            if vs and vs < 2022 then
                arch = "msvc2019_64"
            end
        end

        -- aqt always (re)installs the base SDK plus the requested modules, so
        -- download into a temp dir and merge only the result into the shared
        -- SDK (overwriting identical base files is harmless).
        local tmpdir = path.join(package:installdir(), "aqt_charts_tmp")
        os.rmdir(tmpdir)
        os.mkdir(tmpdir)

        local aqt_args = {"install-qt", "-O", tmpdir, pseudo_host, "desktop", versionstr, arch, "--modules", "qtcharts"}
        os.vrunv("aqt", aqt_args)

        local srcroot = path.join(tmpdir, versionstr, arch)
        if not os.isdir(srcroot) then
            srcroot = path.join(tmpdir, versionstr)
        end

        -- File-by-file merge so we never depend on directory-merge semantics
        -- of os.cp.  Copy the whole downloaded tree into the shared SDK.
        local function merge_dir(src, dst)
            if not os.isdir(src) then
                return
            end
            os.mkdir(dst)
            for _, f in ipairs(os.files(path.join(src, "**"))) do
                local rel = path.relative(f, src)
                local d = path.join(dst, rel)
                os.mkdir(path.directory(d))
                os.cp(f, d)
            end
        end
        for _, sub in ipairs({"bin", "lib", "include", "qml", "plugins", "mkspecs", "libexec", "resources"}) do
            merge_dir(path.join(srcroot, sub), path.join(sdkdir, sub))
        end

        os.rmdir(tmpdir)
    end)

    -- Provide the link so `add_packages("qt6charts")` contributes Qt6Charts.
    -- The lib itself lives in the shared SDK (merged in on_install), whose
    -- libdir is already on the link line via qt6base, but we make it explicit.
    on_fetch(function (package)
        local qtbase = package:dep("qt6base")
        local qt = qtbase and qtbase:fetch()
        if not qt then
            return
        end
        local includedir = qt.includedir
        return {
            includedirs = {includedir, path.join(includedir, "QtCharts")},
            links = {"Qt6Charts"},
            linkdirs = qt.libdir,
            syslinks = package:data("syslinks")
        }
    end)
