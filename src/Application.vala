/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Aral Balkan <mail@ar.al>
 */

namespace Comet {
    public GLib.Settings saved_state;

    public class Application : Gtk.Application {

        public static string binary_path;
        public static string flatpak_id;
        public static bool is_running_as_flatpak;

        string SUMMARY;
        string COPYRIGHT;

        public Comet.Model model;

        private File commit_message_file;
        private bool launched_with_file = false;

        construct {
            // Setup localisation.
            GLib.Intl.setlocale (LocaleCategory.ALL, "");
            GLib.Intl.bindtextdomain (Constants.Config.GETTEXT_PACKAGE, Constants.Config.LOCALEDIR);
            GLib.Intl.bind_textdomain_codeset (Constants.Config.GETTEXT_PACKAGE, "UTF-8");
            GLib.Intl.textdomain (Constants.Config.GETTEXT_PACKAGE);

            COPYRIGHT = _("Made with ♥ by Small Technology Foundation, a tiny, independent not-for-profit")
            + " (https://small-tech.org).\n\n"
            + _("Small Technology are everyday tools for everyday people designed to increase human welfare, not corporate profits.")
            + "\n\n"
            +_("Like this? Fund us!") + " https://small-tech.org/fund-us" + "\n\n"
            + _("Copyright") + " © 2021 Aral Balkan (https://ar.al)" + "\n\n"
            + _("License GPLv3+: GNU GPL version 3") + " (http://gnu.org/licenses/gpl.html)"
            + _("This is free software: you are free to change and redistribute it.\nThere is NO WARRANTY, to the extent permitted by law.");

            SUMMARY = _("Write better Git commit messages.");
        }


        public Application () {
            Object(
                application_id: "org.small_tech.comet",
                flags:
                    /* We handle file opens. */
                    ApplicationFlags.HANDLES_OPEN
                    /* We can have more than one instance active at once. */
                    | ApplicationFlags.NON_UNIQUE
            );
            saved_state = new GLib.Settings ("org.small_tech.comet.saved-state");

            //
            // Set command-line option handling.
            //

            // The option context parameter string is displayed next to the
            // list of options on the first line of the --help screen.
            set_option_context_parameter_string (_("<path-to-git-commit-message-file>"));

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
                _("Show version number and exit"),
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
                    print (@"Comet $(Constants.Config.VERSION)\n");

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
                    print (_("Error: Too many files (%d).").printf (files.length));
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
            Gtk.IconTheme.get_default ().add_resource_path ("/org/small_tech/comet");

            // Use the person’s preferred color scheme.
            // See: https://docs.elementary.io/develop/apis/color-scheme
            // (We’re setting this up here instead of in the base window class
            // in case the Application class needs to show an error dialog, etc.)
            use_preferred_color_scheme ();

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


        private void use_preferred_color_scheme () {
            // Set color scheme of app based on person’s preference.
            var granite_settings = Granite.Settings.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();
            gtk_settings.gtk_application_prefer_dark_theme
                = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

            // Listen for changes in person’s color scheme settings
            // and update color scheme of app accordingly.
            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme
                    = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            });
        }


        private void show_commit_message_file_error (FileError error) {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Comet can’t read the Git commit message."),
                _("The Report Error button will take you to a pre-filled issue on GitHub that you can submit to help improve Comet."),
                "process-stop",
                Gtk.ButtonsType.CLOSE
            );
            message_dialog.badge_icon = new ThemedIcon("comet-128");

            var report_error_button = new Gtk.Button.with_label (_("Report Error"));
            report_error_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            message_dialog.add_action_widget (report_error_button, Gtk.ResponseType.ACCEPT);
            message_dialog.show_error_details (error.message);
            message_dialog.show_all ();

            message_dialog.response.connect ((response_id) => {
               if (response_id == Gtk.ResponseType.ACCEPT) {
                    try {
                        // Note: these are *not* translatable strings on purpose as we
                        // want the issues to be in English only.
                        var title = Uri.escape_string ("Error: Cannot read Git commit message file");
                        var body = Uri.escape_string (@"Comet could not read the Git commit message file on launch and failed with the following error:\n\n```\n$(error.message)\n```");
                        AppInfo.launch_default_for_uri (@"https://github.com/small-tech/comet/issues/new/?title=$(title)&body=$(body)", null);
                    } catch (Error error) {
                        warning (error.message);
                    }
                }
            });

            message_dialog.run ();
        }


        public static int main (string[] commandline_arguments) {
            flatpak_id = Environment.get_variable ("FLATPAK_ID");
            is_running_as_flatpak = flatpak_id != null;

            // This removes the Gtk-Message: Failed to load module "canberra-gtk-module"
            // that plagues every elementary OS 6 (Odin) app at the moment when
            // running via Flatpak.
            if (is_running_as_flatpak) {
                Log.set_writer_func (logWriterFunc);
            }
            binary_path = File.new_for_path (commandline_arguments[0]).get_path();

            return new Application ().run (commandline_arguments);
        }


        private static LogWriterOutput logWriterFunc (LogLevelFlags log_level, [CCode (array_length_type = "gsize")] LogField[] fields) {
            return log_level == LogLevelFlags.LEVEL_MESSAGE ? LogWriterOutput.HANDLED : LogWriterOutput.UNHANDLED;
        }
    }
}
