-- In-tree vendored libraries (NOT git submodules). They are built as normal
-- xmake targets and consumed by the FOXTracker target via add_deps().
--
-- Both targets use Qt6, so they use the `qt.static` rule. On MSVC that rule
-- injects the Qt6-required conformance flags (/Zc:__cplusplus, /permissive-),
-- the QT_*_LIB defines and the QtCore link, and it runs moc on any Q_OBJECT
-- header listed in add_files() (see freetrack's ftnoir_protocol_ft.h).

target("accela_filter")
    set_kind("static")
    add_rules("qt.static")
    add_files("accela_filter/*.cpp")
    -- `accela_filter` is public so dependents (FOXTracker directly includes
    -- <filter_accela.h> / <accela-settings.hpp>) inherit the include path.
    add_includedirs("accela_filter", path.join(os.projectdir(), "inc"), {public = true})
    add_packages("qtbase", "qt6widgets", "eigen", "opencv")
    set_languages("c++17")

target("freetrack")
    set_kind("static")
    add_rules("qt.static")
    add_files(
        "freetrack/*.cpp",
        "freetrack/csv/*.cpp",
        "freetrack/freetrackclient/*.c",
        -- Q_OBJECT header: the qt.static rule runs moc on it.
        "freetrack/ftnoir_protocol_ft.h"
    )
    -- `lib/` is on the include path so `<freetrack/ftnoir_protocol_ft.h>` and
    -- `<accela-settings.hpp>` / `<filter_accela.h>` resolve, matching CMake.
    add_includedirs(
        ".",
        "freetrack",
        "freetrack/csv",
        "freetrack/freetrackclient",
        "accela_filter",
        path.join(os.projectdir(), "inc")
    )
    add_packages("qtbase", "qt6widgets", "qt6network", "yaml-cpp", "eigen", "opencv")
    add_deps("accela_filter")
    set_languages("c++17")

-- ---------------------------------------------------------------------------
-- Git-submodule dependencies, built as plain targets (no xmake package
-- wrapping). They are pulled in via add_deps() from the FOXTracker target.
-- ---------------------------------------------------------------------------

-- PS3 Eye camera driver, built from the `lib/PS3EYEDriver` submodule. When the
-- submodule is not initialized a header-only stub (cmake/ps3eye_stub) is used
-- instead, mirroring the original CMake behaviour.
target("ps3eye")
    set_kind("static")
    set_languages("c++11", "c11")
    add_packages("libusb")

    local driver_src = path.join(os.projectdir(), "lib", "PS3EYEDriver", "src", "ps3eye.cpp")
    if os.isfile(driver_src) then
        add_files(
            "PS3EYEDriver/src/ps3eye.cpp",
            "PS3EYEDriver/src/ps3eye_capi.cpp"
        )
        -- The driver includes "libusb.h" (no libusb-1.0 prefix); expose the
        -- libusb-1.0 include directory so that header resolves. add_packages()
        -- already contributes libusb's own include path, so adding this extra
        -- dir is harmless even if libusb's package already points at it.
        on_load(function (target)
            local libusb = target:pkg("libusb")
            if libusb then
                target:add("includedirs", libusb:installdir("include", "libusb-1.0"), {public = true})
            end
        end)
    else
        -- Header-only stub fallback when the submodule is missing.
        set_kind("headeronly")
        add_includedirs(path.join(os.projectdir(), "cmake", "ps3eye_stub"), {public = true})
    end
    -- `<PS3EYEDriver/src/ps3eye.h>` resolves from here.
    add_includedirs("PS3EYEDriver", {public = true})

-- QJoysticks (https://github.com/alex-spataru/QJoysticks), built from the
-- `lib/QJoysticks` submodule. Qt's moc is required (Q_OBJECT class) and SDL2 is
-- embedded statically.
target("qjoysticks")
    set_kind("static")
    add_rules("qt.static")
    set_languages("c++17")

    local srcroot = path.join(os.projectdir(), "lib", "QJoysticks")
    on_load(function (target)
        if not os.isfile(path.join(srcroot, "CMakeLists.txt")) then
            raise("QJoysticks submodule is missing. Run: git submodule update --init --recursive")
        end
    end)

    add_files(
        "QJoysticks/src/*.cpp",
        "QJoysticks/src/QJoysticks/*.cpp",
        "QJoysticks/etc/resources/qjoysticks-res.qrc",
        -- Q_OBJECT headers need to be listed for qt.static to run moc
        "QJoysticks/src/QJoysticks.h",
        "QJoysticks/src/QJoysticks/SDL_Joysticks.h",
        "QJoysticks/src/QJoysticks/VirtualJoystick.h"
    )
    add_includedirs("QJoysticks/src", {public = true})
    add_defines("SDL_SUPPORTED", "SDL_MAIN_HANDLED", {public = true})
    add_defines("QJOYSTICKS_STATIC", {public = true})
    if is_plat("windows") then
        add_defines("SDL_WIN", {public = true})
    end
    add_packages("qtbase", "qt6widgets", "libsdl2")

-- UGlobalHotkey (https://github.com/petrows/UGlobalHotkey), built from the
-- `lib/UGlobalHotkey` submodule. Upstream uses the Qt5 nativeEvent signature
-- `long *result`; Qt6 changed it to `qintptr *`, so the same substitution the
-- original CMake applied is performed on generated copies before compiling.
target("uglobalhotkey")
    set_kind("static")
    add_rules("qt.static")
    set_languages("c++17")
    -- static build: define _STATIC so the header does not use dllimport/dllexport
    add_defines("UGLOBALHOTKEY_STATIC", {public = true})
    add_packages("qtbase", "qt6widgets")

    local srcdir = path.join(os.projectdir(), "lib", "UGlobalHotkey")
    on_load(function (target)
        if not os.isfile(path.join(srcdir, "uglobalhotkeys.cpp")) then
            raise("UGlobalHotkey submodule is missing. Run: git submodule update --init --recursive")
        end
        -- Generate patched copies (long* -> qintptr*) in the autogen dir so the
        -- submodule sources are never modified in place.
        local gendir = target:autogendir()
        os.mkdir(gendir)
        local files = {
            "uglobalhotkeys.h", "uglobalhotkeys.cpp",
            "ukeysequence.h", "ukeysequence.cpp",
            "uexception.h", "uexception.cpp",
            "hotkeymap.h", "uglobal.h",
        }
        for _, f in ipairs(files) do
            local content = io.readfile(path.join(srcdir, f))
            content = content:replace("long *", "qintptr *", {plain = true})
            -- patch uglobal.h to support static linking (empty export)
            if f == "uglobal.h" then
                content = content:replace(
                    "#if defined(UGLOBALHOTKEY_LIBRARY)\n#  define UGLOBALHOTKEY_EXPORT Q_DECL_EXPORT\n#else\n#  define UGLOBALHOTKEY_EXPORT Q_DECL_IMPORT\n#endif",
                    "#if defined(UGLOBALHOTKEY_STATIC)\n#  define UGLOBALHOTKEY_EXPORT\n#elif defined(UGLOBALHOTKEY_LIBRARY)\n#  define UGLOBALHOTKEY_EXPORT Q_DECL_EXPORT\n#else\n#  define UGLOBALHOTKEY_EXPORT Q_DECL_IMPORT\n#endif",
                    {plain = true})
            end
            io.writefile(path.join(gendir, f), content)
        end
        target:add("includedirs", gendir, {public = true})
        -- The Q_OBJECT headers are listed so the qt.static rule runs moc on them.
        target:add("files", path.join(gendir, "uglobalhotkeys.h"))
        target:add("files", path.join(gendir, "ukeysequence.h"))
        target:add("files", path.join(gendir, "uglobalhotkeys.cpp"))
        target:add("files", path.join(gendir, "ukeysequence.cpp"))
        target:add("files", path.join(gendir, "uexception.cpp"))
    end)
