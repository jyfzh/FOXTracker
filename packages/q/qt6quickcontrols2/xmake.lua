-- Local QtQuickControls2 package.
--
-- The xrepo qt6base SDK does not necessarily include the QtQuickControls2
-- addon. Fetch the module with aqt and merge it into the shared qt6base SDK so
-- the standard Qt package discovery and deployment logic can find it.
package("qt6quickcontrols2")
    set_kind("library")
    set_homepage("https://www.qt.io")
    set_description("Qt 6 Quick Controls 2 module")
    set_license("LGPL-3")

    -- Keep the same versions as qt6base / qt6charts.
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
        -- Use the same Qt SDK and aqt version as the other local Qt module.
        package:add("deps", "qt6base", {debug = package:is_debug(), version = package:version_str()})
        package:add("deps", "aqt")
        package:add("deps", "qt6core", "qt6gui", "qt6qml", "qt6quick", {debug = package:is_debug(), version = package:version_str()})
        package:data_set("libname", "QuickControls2")

        if package:is_plat("iphoneos") then
            package:data_set("frameworks", {"QtQuickControls2"})
        end
    end)

    on_install(function (package)
        -- Locate the shared SDK directory owned by qt6base.
        local qtbase = package:dep("qt6base")
        local sdkdir = qtbase and qtbase:installdir()
        if not sdkdir or not os.isdir(sdkdir) then
            sdkdir = package:installdir()
        end

        -- Avoid downloading the same addon again on incremental installs.
        if os.isfile(path.join(sdkdir, "lib", "Qt6QuickControls2.lib")) or
           os.isfile(path.join(sdkdir, "lib", "Qt6QuickControls2d.lib")) then
            return
        end

        local versionstr = package:version():shortstr()

        -- Resolve the host/arch tuple expected by aqt on Windows.
        local pseudo_host = "windows"
        local arch = "msvc2022_64"
        local msvc = package:toolchain("msvc")
        if msvc then
            local vs = tonumber(msvc:config("vs") or "2022")
            if vs and vs < 2022 then
                arch = "msvc2019_64"
            end
        end

        -- Download into a temporary prefix, then merge only the Qt tree into
        -- the shared SDK. aqt also installs the base SDK in that prefix.
        local tmpdir = path.join(package:installdir(), "aqt_quickcontrols2_tmp")
        os.rmdir(tmpdir)
        os.mkdir(tmpdir)

        local aqt_args = {"install-qt", "-O", tmpdir, pseudo_host, "desktop", versionstr, arch, "--modules", "qtquickcontrols2"}
        os.vrunv("aqt", aqt_args)

        local srcroot = path.join(tmpdir, versionstr, arch)
        if not os.isdir(srcroot) then
            srcroot = path.join(tmpdir, versionstr)
        end

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

    on_fetch(function (package)
        local qtbase = package:dep("qt6base")
        local qt = qtbase and qtbase:fetch()
        if not qt then
            return
        end
        local includedir = qt.includedir
        return {
            includedirs = {includedir, path.join(includedir, "QtQuickControls2")},
            links = {package:is_debug() and "Qt6QuickControls2d" or "Qt6QuickControls2"},
            linkdirs = qt.libdir,
            syslinks = package:data("syslinks")
        }
    end)
