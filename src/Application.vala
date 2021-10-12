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

        public Comet.Model model;
        private File commit_message_file;
        private bool launched_with_file = false;

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

                launched_with_file = true;
                activate ();
            });
        }


        protected override void activate () {
            // Custom icon
            Gtk.IconTheme.get_default ().add_resource_path ("/com/github/small_tech/comet");

            if (!launched_with_file) {
                // Person likely launched the app via the desktop.
                // Show the welcome/configuration screen.
                WelcomeWindow window = new WelcomeWindow (this);
                window.show();
                return;
            }

            // Note: we would ideally pass a reference to model
            // here but it doesn’t appear that we can add a new construct-only
            // property in the GObject constructor of a subclass in Vala.
            //
            // TODO: Confirm: is this really true? I have a hard time
            // believing such a simple thing is impossible.

            model = new Comet.Model ();

            try {
                model.initialise_with_commit_message_file (commit_message_file);
                MainWindow window = new MainWindow (this);
                window.show ();
            } catch (FileError error) {
                show_commit_message_file_error (error);
            }
        }

        private void show_commit_message_file_error (FileError error) {
            // TODO: Remove redundancy. The colour scheme code is replicated
            // from BaseWindow. Pull out to a common utility class.

            // ===

            // Set colour scheme of app based on person’s preference.
            var granite_settings = Granite.Settings.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();
            gtk_settings.gtk_application_prefer_dark_theme
                = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

            // Listen for changes in person’s colour scheme settings
            // and update color scheme of app accordingly.
            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme
                    = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            });

            // ===

            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                "Comet can’t read the git commit message.",
                "The Report Error button will take you to a pre-filled issue on GitHub that you can submit to help improve Comet.",
                "process-stop",
                Gtk.ButtonsType.CLOSE
            );
            message_dialog.badge_icon = new ThemedIcon("comet-128");

            var report_error_button = new Gtk.Button.with_label ("Report Error");
            report_error_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            message_dialog.add_action_widget (report_error_button, Gtk.ResponseType.ACCEPT);
            message_dialog.show_error_details (error.message);
            message_dialog.show_all ();

            message_dialog.response.connect ((response_id) => {
               if (response_id == Gtk.ResponseType.ACCEPT) {
                    try {
                        var title = Camel.URL.encode ("Error: Cannot read git commit message file", ":;@/");
                        var body = Camel.URL.encode (@"Comet could not read the git commit message file on launch and failed with the following error:\n\n```\n$(error.message)\n```\n\nWould appreciate it if you could look into it.\n\nThanks!", ":;@/");
                        AppInfo.launch_default_for_uri (@"https://github.com/small-tech/comet/issues/new/?title=$(title)&body=$(body)", null);
                    } catch (Error error) {
                        warning (error.message);
                    }
                }
            });

            message_dialog.run ();
        }

        public static int main (string[] commandline_arguments) {
            return new Application ().run (commandline_arguments);
        }
    }
}
