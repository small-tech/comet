# Comet

![Comet screenshot](https://small-tech.org/downloads/comet/screenshots/en/comet-header.jpg)

_Write better Git commit messages._

A distraction-free Git commit message editor with spell-check, first line character limit warnings, and emoji support.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/org.small_tech.comet)

## Get the wallpaper

Just like [Catts](https://github.com/small-tech/catts) and [Watson](https://github.com/small-tech/watson), Comet also has a lovely wallpaper designed by [Margo de Weerdt](https://www.margodeweerdt.com/) that you can download below (just right-click or long-tap and save it to your machine).

![An illustration of The Little Prince flying through a multi-coloured cosmos of blues and purples towards the sun with a captured comet that’s emanating a tail of yellows and reds. Characters from previous projects can be seen on the planets around him, like the cats in Catts and Sherlock and Watson, who are in a boat on Earth, and Enola who is on the moon.](https://small-tech.org/downloads/comet/wallpaper/comet-wallpaper-4k-by-margo-de-weerdt-small-technology-foundation.jpg)

_The wallpaper is released under [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/). Please credit [Margo de Weerdt](https://www.margodeweerdt.com/) and [Comet](https://github.com/small-tech/catts) by [Small Technology Foundation](https://small-tech.org)._

## System requirements

  - [elementary OS](https://elementary.io) 6 (Odin)

_Comet is designed specifically for elementary OS 6. If you want a similar app for GNOME in general, please see [Commit](https://flathub.org/apps/details/re.sonny.Commit), which is a fork of my previous app, [Gnomit](https://flathub.org/apps/details/org.small_tech.Gnomit), which is being maintained by Sonny Piers and which, itself, was inspired by Mayur’s excellent [Komet](https://github.com/zorgiepoo/Komet) app that I loved using back when my development machine was a Mac._

## Installation and usage

1. Install Comet from AppCenter.
2. Launch Comet from the _Applications Menu_.

When launched from the _Applications Menu_, Comet displays the Welcome Screen and automatically sets itself as your default Git commit message editor.

Comet remembers your previous editor and restores it should you disable it in the future.

When Comet is enabled as your default Git commit message editor, it launches automatically whenever you make a Git commit.

### About spell check

Spell checking will try to automatically match your system’s locale but the dictionaries available are based on the ones installed on elementary OS by default. Needless to say, these have a Western bias.

So, if you want spell checking to work with Turkish, for example, you have to manually install the dictionary.

e.g., for Turkish, copy and paste this into Terminal:

```shell
sudo apt install hunspell-tr
```

You can see which dictionaries are installed by running the following command in Terminal:

```shell
apt search hunspell | grep installed
```

### About the first line character limit

Using the numerical stepper in the _Settings Menu_ in the header bar, you can set the first line character limit to any value from 50 to 132. You can also use the shortcut buttons in the _Settings Menu_ to set the limit to:

  - Dogmatic (50)
  - GitHub truncation (72)
  - GitLab truncation (100)

The _Dogmatic (50)_ limit is based on the assumption that [the median message length in the Git projects’s own repository](https://preslav.me/2015/02/21/what-s-with-the-50-72-rule/) is somehow an indication of message quality. (Somewhat ironically, [Linus Torvald’s example of a good Git message](https://github.com/torvalds/subsurface-for-dirk/blob/a48494d2fbed58c751e9b7e8fbff88582f9b2d02/README#L88) has 65 characters in the first line.)

The _GitHub trunctation (72)_ and _GitLab truncation (100)_ limits are the lengths beyond which GitHub and GitLab truncate the first line of a commit message when displaying it ([GitHub truncates messages longer than 72 characters to 69 characters](https://robertcooper.me/post/git-commit-messages#subject-line-less-than-or-equal-to-72-characters-in-length) and [GitLab truncates lines over 100 characters to 80 characters]((https://gitlab.com/gitlab-org/gitlab-foss/-/blob/2859e8d54f948184ac489afea995c65ed0ca325c/app/models/commit.rb#L172))).

(GitHub’s own limit is based on an [80-character terminal screen limit](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).)

The default character limit in Comet is the GitHub truncation limit.

Comet will not prevent you from exceeding the character limit but it will warn you as you approach the limit and highlight overflowing characters if you exceed it.

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

### Accessibility Notes

#### Welcome screen

When the app first loads, the initial option button is selected in the Welcome screen. This is an accessibility issue for two reasons:

1. The description (not title) of that option is read out by Orca.
2. The rest of the window’s contents are not read in order unless the person invokes Orca’s “Speak entire window using flat review” command.

This is an issue that affects all elementary OS apps that use the standard Granite Welcome screen widget and is being tracked in [Issue #526 on the Granite bug tracker](https://github.com/elementary/granite/issues/536).

#### Editor

The title, Git command, and Git commit message type detail (e.g., the branch to be committed) are read out and the person is informed that the the Git commit message editor component has focus.

To have the Git commit message comment read out, please invoke Orca’s “Speak entire window using flat review” command.

If you have ideas for improving the accessibility of Comet, please voice them in the [discussions](https://github.com/small-tech/comet/discussions) or [open an issue](https://github.com/small-tech/comet/issues).

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
2. Run `build/org.small_tech.comet tests/<name of test message>`

This will build and run Comet using one of the test Git commit messages found in the tests folder.

If you want to test the native binary with actual Git commits, you must register the binary as your default editor manually.

```shell
git config --global core.editor <full path to build/org.small_tech.comet>
```

To test the Welcome screen, run the binary without passing any arguments:

```shell
build/org.small_tech.comet
```

Note that the native binary, unlike the Flatpak package that is distributed to people on the elementary OS AppCenter, is not sandboxed and uses different calls to configure Git. While it should behave identically to the Flatpak package, always make sure to test comprehensively with the Flatpak package before creating releases.

#### Flatpak testing

Testing with the Flatpak build is slower but you can be sure that you’re seeing exactly the same behaviour that people who install and run Comet from the elementary OS AppCenter will see.

1. Run `task/package`
2. Either carry out a `git commit` or, to run Comet using one of the test messages:

    ```shell
    flatpak run org.small_tech.comet tests/<name of test message>
    ```

To test the Welcome screen, either launch Comet from the Applications Menu or, via Terminal, run the Comet flatpak without passing it any arguments:

```shell
flatpak run org.small_tech.comet
```

### Debugging

In [VSCodium](#vscodium), press <kbd>Control</kbd> + <kbd>Shift</kbd> + B → _Build all targets_ to build and <kbd>F5</kbd> to run and debug.

To pass a test commit message to Comet to debug with, edit the _.vscode/launch.json_ file and add the argument to the array referenced by the `args` property.

For example, to debug with a standard Git commit message without a body:

```json
{
  "version": "0.2.0",
  "configurations": [

    {
      "type": "lldb",
      "request": "launch",
      "name": "Debug",
      "program": "${workspaceFolder}/build/org.small_tech.comet",
      "args": ["tests/message-without-body"],
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

If you do not pass an argument (if `"args": []`), Comet will launch in the debugger with the Welcome screen.

### AppCenter preview

To test how the app will look on AppCenter, do the following:

1. Uncomment the `<icon/>` tag in _data/comet.appdata.xml.in_.

2. Build the app:
    ```shell
    task/build
    ```

3. Run AppCenter, asking it to display your local _appdata.xml_:
    ```shell
    io.elementary.appcenter --load-local build/org.small_tech.comet.appdata.xml
    ```

### Translations

#### Add a new language

1. Add the language code to the [po/LINGUAS](https://github.com/small-tech/comet/blob/main/po/LINGUAS) file.
2. Update translations:

    ```shell
    task/update-translations
    ```

_If you want to help translate but don’t want to clone the repository you can contribute using GitHub’s online interface. Please introduce yourself in the  [discussions](https://github.com/small-tech/comet/discussions) and let us know which language you’d like to work on and we can help you get started._

#### Screenshot translations

In addition to the in-app strings, there are some strings that are shown in the localised screenshots on [Comet’s AppCenter page](https://appcenter.elementary.io/org.small_tech.comet). These have been added as constants in the `Constants.AppCenterCopy` namespace and should appear in the translations along with the other strings.

You do not have to take the screenshots yourself but we’ll make use of the translated strings when we take them.

Also, you do not have to worry about translating the Git comments shown in the screenshots as Git is already localised so they will automatically display in the correct language.

#### Testing

To test the native binary with a locale different to your account’s locale (e.g., to test the Turkish translations):

```shell
# Test the welcome screen
LANGUAGE=tr_TR.utf8 build/org.small_tech.comet

# Test with a commit message
LANGUAGE=tr_TR.utf8 build/org.small_tech.comet tests/message-without-body
```

Note that the message comment will display in English as the test messages are all in English. The comments are localised by Git, not Comet, so to see fully localised output, set either the native binary or the flatpak as your default Git editor with the `LANGUAGE` environment variable set and test with actual commits.

Remember to update the translation files whenever you change localisable strings in your app:

```shell
task/update-translations
```

Also, when you add a new translation, remember to run the installation task to install the new translations before testing via the Meson build. If you’re running the binary with a valid `LANGUAGE` environment variable and it’s not working, it’s most likely because you forgot to do this:

```shell
task/install
```

#### AppCenter preview of translations

To preview the localised strings/screenshots in AppCenter, specify the language while launching AppCenter.

For example, to view how the Turkish localisations will look in the elementary OS AppCenter:

```shell
LANGUAGE=tr_TR.utf8 io.elementary.appcenter --load-local build/org.small_tech.comet.appdata.xml
```

#### Developer tips for translations

Break up long strings into compositions of smaller ones. This is especially useful when some parts of a string should be localised but others shouldn’t. This will lead to fewer errors cropping in through translations forgetting template placeholders, etc.

e.g., if you run `build/org.small_tech.comet --help` from the terminal, you will see a localised summary string. This is how it’s composed as a collection of localisable and non-localisable strings:

```vala
var copyright_message = ""
+ _("Made with ♥ by Small Technology Foundation, a tiny, independent not-for-profit")
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


Remember to comment out the `<icon />` tag in _data/comet.appdata.xml.in_ after you’re done previewing your app in AppCenter or your Flatpak builds will fail.

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
  - Various other graphical assets created using [Penpot](https://penpot.app/).

## Copyright and license

Copyright &copy; 2021-present [Aral Balkan](https://ar.al), [Small Technology Foundation](https://small-tech.org).

Licensed under [GNU GPL version 3.0](./LICENSE).
