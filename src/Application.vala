/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Aral Balkan <mail@ar.al>
 */

namespace Comet {
    public GLib.Settings saved_state;

    public class Application : Gtk.Application {

        static string SUMMARY = """Helps you write better Git commit messages.

  To use, configure Git to use Gnomit as the default editor:

  git config --global core.editor "flatpak run com.github.small_tech.Comet" """;

        static string COPYRIGHT = """Made with ♥ by Small Technology Foundation, a tiny, independent not-for-profit (https://small-tech.org).

Small Technology are everyday tools for everyday people designed to increase human welfare, not corporate profits.

Like this? Fund us! https://small-tech.org/fund-us

Copyright © 2021 Aral Balkan (https://ar.al)

License GPLv3+: GNU GPL version 3 or later (http://gnu.org/licenses/gpl.html)
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.""";

        private bool launched_with_file = false;
        private File commit_message_file;
        private string commit_message_file_path;

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
            set_option_context_parameter_string ("<path-to-git-commit-message-file>");

            // The option context summary is displayed above the set of options
            // on the --help screen.
            set_option_context_summary (SUMMARY);

            // The option context description is displayed below the set of options
            // on the --help screen.
            set_option_context_description (COPYRIGHT);

            // Add option: --version, -v
            add_main_option(
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
                    print (@"Comet $(Constants.VERSION)\n");

                    // OK.
                    return 0;
                }

                // Let the system handle any other command-line options.
                return -1;
            });

            //
            // Signal: Open file.
            //

            open.connect((application, files, hint) => {
                if (files.length > 1) {
                    print (@"Error: Too many files ($(files.length)).");
                    quit ();
                    return;
                }


                commit_message_file = files[0];
                commit_message_file_path = commit_message_file.get_path ();
                print (@"File path: $(commit_message_file_path)\n");
                activate ();
            });
        }


        protected override void activate () {
            // Custom icon
            Gtk.IconTheme.get_default ().add_resource_path ("/com/github/small_tech/comet");

            if (!launched_with_file) {
                // Person likely launched the app via the desktop.
                // TODO: Show the welcome/configuration screen.
                WelcomeWindow window = new WelcomeWindow (this);
                window.show();
                return;
            }
            MainWindow window = new MainWindow (this);
            window.show ();
        }

        public static int main (string[] commandline_arguments) {
            return new Application ().run (commandline_arguments);
        }
    }
}
