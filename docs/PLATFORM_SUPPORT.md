# Platform support

| Platform | Configuration | Verified on this host |
| --- | --- | --- |
| Windows x64 | Existing runner; OnezPH product metadata; native logo; file dialogs, drag/drop, SQLite, PDFium, print plugin and save-before-close | Release build passed |
| Android | Existing runner; com.onezph.zslice; ZSlice label; adaptive logo | Debug APK build passed |
| iOS | Existing runner; com.onezph.zslice; ZSlice label; logo; minimum iOS 14.0 for file_picker | Requires Mac/Xcode and signing |
| macOS | Runner added within the existing project; com.onezph.zslice; ZSlice name; logo; user-selected read-write file entitlements | Requires Mac/Xcode and signing |

Native dialogs, sandboxed Finder drops, physical printer output, accessibility with platform screen readers and real device memory behavior need acceptance tests. Windows requires Visual Studio C++ tools/developer-mode symlinks. Android release signing is not configured for distribution.

Desktop Word conversion uses an installed LibreOffice at its standard path. This host has no LibreOffice. macOS sandbox behavior for launching external conversion engines is unverified and may require a separately packaged conversion service; errors are surfaced. Mobile Word conversion is explicitly unavailable. Source PDF pages are rasterized on all platforms. Fonts and icon payloads are bundled; no runtime icon/font network access is required.
