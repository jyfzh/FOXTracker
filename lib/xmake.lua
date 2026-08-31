-- freetrack uses Qt6, so it uses the `qt.static` rule. On MSVC that rule
-- injects the Qt6-required conformance flags (/Zc:__cplusplus, /permissive-),
-- the QT_*_LIB defines and the QtCore link, and it runs moc on any Q_OBJECT
-- header listed in add_files() (see freetrack's ftnoir_protocol_ft.h).

target("freetrack")
    set_kind("static")
    add_rules("qt.static")
    add_files(
        "freetrack/*.cpp",
        "freetrack/csv/*.cpp",
        -- Q_OBJECT header: the qt.static rule runs moc on it.
        "freetrack/ftnoir_protocol_ft.h"
    )
    -- freetrackclient.c is a Windows DLL client and includes Win32 mapping
    -- APIs. The application-side POSIX shared-memory implementation above is
    -- used on Linux instead.
    if is_plat("windows") then
        add_files("freetrack/freetrackclient/*.c")
    end
    -- Expose the lib root so consumers can include freetrack headers as
    -- <freetrack/ftnoir_protocol_ft.h>. The implementation also depends on
    -- project headers that now live under src/.
    add_includedirs(
        ".",
        "freetrack",
        "freetrack/csv",
        "freetrack/freetrackclient",
        path.join(os.projectdir(), "src"),
        {public = true}
    )
    add_packages("qtbase", "qt6widgets", "qt6network", "yaml-cpp", "eigen", "opencv")
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
            elseif f == "uglobalhotkeys.h" then
                -- The upstream header leaves these handles uninitialized on
                -- Linux when Qt runs under Wayland. Keep the generated copy
                -- safe without modifying the submodule checkout.
                content = content:replace(
                    "    xcb_connection_t* X11Connection;\n    xcb_window_t X11Wid;\n    xcb_key_symbols_t* X11KeySymbs;",
                    "    xcb_connection_t* X11Connection = nullptr;\n    xcb_window_t X11Wid = 0;\n    xcb_key_symbols_t* X11KeySymbs = nullptr;",
                    {plain = true})
            elseif f == "uglobalhotkeys.cpp" then
                -- qpa/qplatformnativeinterface.h is a Qt private header and
                -- is not shipped by many Linux distributions. Qt6 exposes
                -- the same XCB connection through its public native interface.
                content = content:replace(
                    "#include <qpa/qplatformnativeinterface.h>",
                    "#include <QtGui/qguiapplication_platform.h>\n#include <cstdlib>",
                    {plain = true})
                content = content:replace(
                    "    QWindow wndw;\n    void* v = qApp->platformNativeInterface()->nativeResourceForWindow(\"connection\", &wndw);\n    X11Connection = (xcb_connection_t*)v;\n    X11Wid = xcb_setup_roots_iterator(xcb_get_setup(X11Connection)).data->root;\n    X11KeySymbs = xcb_key_symbols_alloc(X11Connection);",
                    "    auto *x11 = qGuiApp->nativeInterface<QNativeInterface::QX11Application>();\n    X11Connection = x11 ? x11->connection() : nullptr;\n    if (X11Connection != nullptr) {\n        X11Wid = xcb_setup_roots_iterator(xcb_get_setup(X11Connection)).data->root;\n        X11KeySymbs = xcb_key_symbols_alloc(X11Connection);\n    }",
                    {plain = true})
                content = content:replace(
                    "    #elif defined(Q_OS_LINUX)\n    regLinuxHotkey(keySeq, id);\n    #endif",
                    "    #elif defined(Q_OS_LINUX)\n    if (X11Connection != nullptr && X11KeySymbs != nullptr)\n        regLinuxHotkey(keySeq, id);\n    else\n        qWarning() << \"Global hotkeys require an X11 session\";\n    #endif",
                    {plain = true})
                content = content:replace(
                    "    xcb_key_symbols_free(X11KeySymbs);",
                    "    if (X11KeySymbs != nullptr)\n        xcb_key_symbols_free(X11KeySymbs);",
                    {plain = true})
                content = content:replace(
                    "    UHotkeyData data;\n    UKeyData keyData = QtKeyToLinux(keySeq);\n\n    xcb_keycode_t *keyC = xcb_key_symbols_get_keycode(X11KeySymbs, keyData.key);\n\n    data.keyCode = *keyC;",
                    "    if (X11Connection == nullptr || X11KeySymbs == nullptr)\n        return;\n\n    UHotkeyData data;\n    UKeyData keyData = QtKeyToLinux(keySeq);\n\n    xcb_keycode_t *keyC = xcb_key_symbols_get_keycode(X11KeySymbs, keyData.key);\n    if (keyC == nullptr) {\n        qWarning() << \"Could not resolve X11 keycode for global hotkey\";\n        return;\n    }\n\n    data.keyCode = *keyC;",
                    {plain = true})
                content = content:replace(
                    "    Registered.insert(id, data);\n}\n\nvoid UGlobalHotkeys::unregLinuxHotkey",
                    "    Registered.insert(id, data);\n    std::free(keyC);\n    xcb_flush(X11Connection);\n}\n\nvoid UGlobalHotkeys::unregLinuxHotkey",
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
