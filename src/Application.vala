/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Aral Balkan <mail@ar.al>
 */

namespace Comet {
    public GLib.Settings saved_state;

    public class Application : Gtk.Application {

        static string SUMMARY = """Helps you write better Git commit messages.

  To use, configure Git to use Gnomit as the default editor:

  git config --global core.editor "flatpak run org.small_tech.Gnomit" """;

        static string COPYRIGHT = """Made with ♥ by Small Technology Foundation, a tiny, independent not-for-profit (https://small-tech.org).

Small Technology are everyday tools for everyday people designed to increase human welfare, not corporate profits.

Like this? Fund us! https://small-tech.org/fund-us

Copyright © 2021 Aral Balkan (https://ar.al)

License GPLv3+: GNU GPL version 3 or later (http://gnu.org/licenses/gpl.html)
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.""";

        public Application () {
            Object(
                application_id: "com.github.small_tech.comet",
                flags:
                    /* We handle file opens. */
                    ApplicationFlags.HANDLES_OPEN
                    /* We can have more than one instance active at once. */
                    | ApplicationFlags.NON_UNIQUE
            );

            saved_state = new GLib.Settings ("com.github.small_tech.comet.saved-state");

            //
            // Set command-line option handling.
            //

            // The option context parameter string is displayed next to the
            // list of options on the first line of the --help screen.
            this.set_option_context_parameter_string("<path-to-git-commit-message-file>");

            // The option context summary is displayed above the set of options
            // on the --help screen.
            this.set_option_context_summary(SUMMARY);

            // The option context description is displayed below the set of options
            // on the --help screen.
            this.set_option_context_description(COPYRIGHT);

            // Add option: --version, -v
            this.add_main_option(
                "version", 'v',
                GLib.OptionFlags.NONE,
                GLib.OptionArg.NONE,
                "Show version number and exit",
                null
            );

            //
            // Signal: Handle local options.
            //

            handle_local_options.connect((application, options) => {
                // Handle option: --version, -v:
                //
                // Print a minimal version string based on the GNU coding standards.
                // https://www.gnu.org/prep/standards/standards.html#g_t_002d_002dversion
                if (options.contains("version")) {
                    print(@"Comet $(Constants.VERSION)");

                    // OK.
                    return 0;
                }

                // Let the system handle any other command-line options.
                return -1;
            });
        }


        protected override void activate () {
            MainWindow window = new MainWindow (this);
            window.show ();
        }

        public static int main (string[] commandline_arguments) {
            return new Application ().run (commandline_arguments);
        }
    }
}
