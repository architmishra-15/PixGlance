# Project

_Mobile version_ for ***"Pix Glance"*** application written in Flutter

## Image Support -
Following are the images supported by `PixGlance` -
- `svg`
- `png`
- `jpg`
- `jpeg`
- `gif`
- `webp`
- `tiff`
- `tif`
- `bmp`
- `heic`
- `heiv`
- `ico`

> More would be added in the future

## Installation - 

Four `apk` files have been provided for installation you can choose according to your system's architechture - 

- [arm64](https://github.com/architmishra-15/PixGlance/releases/download/apk/PixGlance-arm64-v8a.apk)
- [arm](https://github.com/architmishra-15/PixGlance/releases/download/apk/PixGlance-armeabi-v7a.apk)
- [x86_64](https://github.com/architmishra-15/PixGlance/releases/download/apk/PixGlance-x86_64.apk)

### If you don't know or can't understand which one do you need to install, what's your mobile's architecture is, follow the given steps -

 - If you have `Termux` installed then paste the following code -
   
     ```lua
     getprop ro.product.cpu.abi
     ```
- And if you don't want to use terminal or any such thing, then you can use apps like `CPU-Z` to view what architecture your phone is.


### Is there no other way?

You can download this [apk](https://github.com/architmishra-15/PixGlance/releases/download/apk/PixGlance.apk) which can install the app for any architecture.

> :warning: **Warning:** The size of the apk woul be quite larger than the others (about 3x more).


## Coe Structure -
```bash
lib/
├── main.dart                          # App entry point
├── models/
│   └── cached_image.dart             # Data model for cached images
├── screens/
│   ├── home_screen.dart              # Main screen with image viewer
│   ├── image_view_screen.dart        # Full-screen image view
│   ├── cached_images_screen.dart     # List of cached images
│   └── about_screen.dart             # About/info screen
├── services/
│   ├── theme_service.dart            # Theme management
│   ├── cache_service.dart            # Image caching logic
│   └── file_service.dart             # File operations
├── utils/
│   ├── constants.dart                # App constants
│   └── image_utils.dart              # Image utility functions
└── widgets/
├── app_drawer.dart               # Navigation drawer
├── theme_toggle_button.dart      # Theme toggle widget
└── image_viewer.dart             # Image display widget
```

