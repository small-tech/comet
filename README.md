# Comet

![Comet icon](./data/comet-128.svg)

A beautiful git commit message editor for elementary OS.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.small_tech.comet)

## System requirements

  - [Elementary OS](https://elementary.io) 6 (Odin)

Comet is designed specifically for elementary OS 6. If you want a similar app for GNOME in general, please see [Commit](https://flathub.org/apps/details/re.sonny.Commit), which is being developed by Sonny Piers and is a fork of my previous app, [Gnomit](https://flathub.org/apps/details/org.small_tech.Gnomit), which itself was inspired by Mayur’s excellent [Komet](https://github.com/zorgiepoo/Komet) app that I loved using back when my development machine was a Mac.

## Developer notes

### Getting started

Clone this repository and run the install task:

```shell
task/install
```

You can now run the app from either the _Applications Menu_ or using the run task:

```shell
task/run
```

### About

This project is written in [Vala](https://valadoc.org/) and follows the following elementary OS guidelines:

  - [Human Interface Guidelines](https://docs.elementary.io/hig/)
  - [Developer Guidelines](https://docs.elementary.io/develop/)
  - [Coding style](https://docs.elementary.io/develop/writing-apps/code-style)

Please take some time to familiarise yourself with those documents before continuing.

To get your system ready to develop for elementary OS, please see the [Basic Setup](https://docs.elementary.io/develop/writing-apps/the-basic-setup) section of the [elementary OS Developer Documentation](https://docs.elementary.io/develop/).

### Tasks

#### Install

Configures and runs the build, installs settings-related features and translations and refreshes the icon cache.

Run this after you clone this repository to get a working build.

```shell
task/install
```

#### Build

Builds the project.

```shell
task/build
```


#### Run

Builds and runs the executable.

```shell
task/run
```

#### Package

Creates a Flatpak package.

```shell
task/package
```

#### Run Package

Creates and runs a Flatpak package.

```shell
task/run-package
```

### Testing

There are two different ways to test Comet, as there are two ways to build it.

#### Quick testing

The quickest way to build and test Comet is by using Meson and Ninja and creating a native binary:

1. Run `task/build`
2. Run `build/com.github.small_tech.comet tests/<name of test message>`

This will build and run Comet using one of the test git commit messages found in the tests folder.

If you want to test the native binary with actual git commits, you must register the binary as your default editor manually.

```shell
git config --global core.editor <full path to build/com.github.small_tech.comet>
```

To test the Welcome screen, run the binary without passing any arguments:

```shell
build/com.github.small_tech.comet
```

Note that the native binary, unlike the Flatpak package that is distributed to people on the elementary OS AppCenter, is not sandboxed and uses different calls to configure git. While it should behave identically to the Flatpak package, always make sure to test comprehensively with the Flatpak package before creating releases.

#### Flatpak testing

Testing with the Flatpak build is slower but you can be sure that you’re seeing exactly the same behaviour that people who install and run Comet from the elementary OS AppCenter will see.

1. Run `task/package`
2. Either carry out a `git commit` or, to run Comet using one of the test messages:

    ```shell
    flatpak run com.github.small_tech.comet tests/<name of test message>
    ```

To test the Welcome screen, either launch Comet from the Applications Menu or, via Terminal, run the Comet flatpak without passing it any arguments:

```shell
flatpak run com.github.small_tech.comet
```

### Debugging

In [VSCodium](#vscodium), press <kbd>Control</kbd> + <kbd>Shift</kbd> + B → _Build all targets_ to build and <kbd>F5</kbd> to run and debug.

To pass a test commit message to Comet to debug with, edit the _.vscode/launch.json_ file and add the argument to the array referenced by the `args` property.

For example, to debug with a standard git commit message without a body:

```json
{
  "version": "0.2.0",
  "configurations": [

    {
      "type": "lldb",
      "request": "launch",
      "name": "Debug",
      "program": "${workspaceFolder}/build/com.github.small_tech.comet",
      "args": ["tests/message-without-body"],
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

If you do not pass an argument (if `"args": []`), Comet will launch in the debugger with the Welcome screen.

### Translations

To test the native binary with a locale different to your account’s locale (e.g., to test the Turkish translations):

```shell
# Test the welcome screen
LANGUAGE=tr_TR.utf8 build/com.github.small_tech.comet

# Test with a commit message
LANGUAGE=tr_TR.utf8 build/com.github.small_tech.comet tests/message-without-body
```

Note that the message comment will display in English as the test messages are all in English. The comments are localised by git, not Comet, so to see fully localised output, set either the native binary or the flatpak as your default git editor with the `LANGUAGE` environment variable set and test with actual commits.

Remember to update the translation files whenever you change localisable strings in your app:

```shell
tasks/update-translations
```

__Tip:__ Break up long strings into compositions of smaller ones. This is especially useful when some parts of a string should be localised but others shouldn’t. This will lead to fewer errors cropping in through translations forgetting template placeholders, etc.

e.g., if you run `build/com.github.small_tech.comet --help` from the terminal, you will see a localised summary string. This is how it’s composed as a collection of localisable and non-localisable strings:

```vala
var copyright_message = _("Made with ♥ by Small Technology Foundation, a tiny, independent not-for-profit")
+ " (https://small-tech.org).\n\n"
+ _("Small Technology are everyday tools for everyday people designed to increase human welfare, not corporate profits.")
+ "\n\n"
+_("Like this? Fund us!") + " https://small-tech.org/fund-us" + "\n\n"
+ _("Copyright") + " © 2021 Aral Balkan (https://ar.al)" + "\n\n"
+ _("License GPLv3+: GNU GPL version 3") + " (http://gnu.org/licenses/gpl.html)"
+ _("This is free software: you are free to change and redistribute it.\nThere is NO WARRANTY, to the extent permitted by law.");
```

This leads to translation strings that provide enough context for translators without requiring them to maintain formatting and the non-localised bits and should lead to fewer errors.

Here’s what the Turkish translation of this section looks like:

```po
#: src/Application.vala:30
msgid ""
"Made with ♥ by Small Technology Foundation, a tiny, independent not-for-"
"profit"
msgstr ""
"♥ Minicik, bağımsız ve kar amacı gütmeyen Small Technology Foundation (Küçük "
"Teknoloji Kurumu) tarafından sevgiyle yapılmıştır"

#: src/Application.vala:32
msgid ""
"Small Technology are everyday tools for everyday people designed to increase "
"human welfare, not corporate profits."
msgstr ""
"Küçük Teknoloji kurumsal karları değil, insan refahını artırmak için "
"yaratılan, günlük insanlar için günlük aletlerdir."

#: src/Application.vala:34
msgid "Like this? Fund us!"
msgstr "Bunu beğendiniz mi? Bizi destekleyin!"

#: src/Application.vala:35
msgid "Copyright"
msgstr "Telif Hakkı"

#: src/Application.vala:36
msgid "License GPLv3+: GNU GPL version 3"
msgstr "Lisansı GPLv3: GNU GPL sürüm 3"

#: src/Application.vala:37
msgid ""
"This is free software: you are free to change and redistribute it.\n"
"There is NO WARRANTY, to the extent permitted by law."
msgstr ""
"Bu özgür yazılımdır: değiştirebilirsiniz ve dağıtabilirsiniz.\n"
"Yasaların izin verdiği kapsamda hiçbir garanti içermez."
```

### VSCodium

You do _not_ need to use [VSCodium](https://vscodium.com) to hack on Comet.

You can, for instance, use elementary OS [Code](https://docs.elementary.io/develop/writing-apps/the-basic-setup#code), which comes pre-installed, or a different third-party editor like [Builder](https://apps.gnome.org/en/app/org.gnome.Builder/).

However, if you do have VSCodium installed, there are a number of extensions that will make contributing to Comet easier:

  - [Vala](https://github.com/Prince781/vala-vscode) (`codium --install-extension prince781.vala`)
  - [Meson](https://github.com/asabil/vscode-meson) (`codium --install-extension asabil.meson`)
  - [CodeLLDB](https://github.com/vadimcn/vscode-lldb) (`codium --install-extension vadimcn.vscode-lldb`)
  - [XML](https://github.com/redhat-developer/vscode-xml) (`codium --install-extension redhat.vscode-xml`)
  - [YAML](https://github.com/redhat-developer/vscode-yaml) (`codium --install-extension redhat.vscode-yaml`)

If you have the Meson and CodeLLDB extensions installed, you can run and debug the app using the Run and Debug feature (or just hit <kbd>F5</kbd>.)

## Continuous integration

[Continuous Integration](https://docs.elementary.io/develop/writing-apps/our-first-app/continuous-integration) is set up for this repository.

## Submitting the app

Please make sure you [review the AppCenter publishing requirements](https://docs.elementary.io/develop/appcenter/publishing-requirements) before [submitting the app](https://developer.elementary.io/) to the [elementary OS AppCenter](https://appcenter.elementary.io/).

## It’s elementary, my dear…

This project was initially generated by [Watson](https://github.com/small-tech/watson), a tool for quickly setting up a new elementary OS 6 app that follows platform [human interface](https://docs.elementary.io/hig/) and [development](https://docs.elementary.io/develop/) guidelines.

## Acknowledgements

  - Comet wallpaper created by [Margo de Weerdt](https://www.margodeweerdt.com/).
  - Comet icon created using [Krita](https://krita.org/en/).

## Copyright and license

Copyright &copy; 2021-present [Aral Balkan](https://ar.al), [Small Technology Foundation](https://small-tech.org).

Licensed under [GNU GPL version 3.0](./LICENSE).
