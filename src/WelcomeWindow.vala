// TODO: This shouldn’t be its own window, it should be a conditional
// ===== view in the main window.
namespace Comet {
    public class WelcomeWindow : Comet.BaseWindow {

        private bool comet_is_enabled;
        private Granite.Widgets.WelcomeButton enable_disable_button;
        private Comet.Widgets.Welcome welcome;

        public WelcomeWindow (Comet.Application application) {
            base (application);
        }

        protected override void create_layout () {
            comet_is_enabled = is_comet_enabled ();

            if (welcome == null) {
                // This is the first time the view is being created. Enable
                // Comet if it’s not enabled to save the person some work.
                if (!comet_is_enabled) {
                    // If Comet is not enabled, enable it so the person does not
                    // have to do this manually (reduce effort).
                    if (enable_comet ()) {
                        // Enabled Comet.
                        comet_is_enabled = true;
                    }
                }
            } else {
                // This is not the first time the view is being created.
                // Remove the old view.
                grid.remove(welcome);
            }

            welcome = new Comet.Widgets.Welcome (
                "Comet",
                "A beautiful git commit message editor.",
                comet_is_enabled
            );

            int enable_disable_button_index;
            if (comet_is_enabled) {
                enable_disable_button_index = welcome.append ("comet-disable", _("Disable Comet"), _("Revert to using your previous editor for git commit messages."));
            } else {
                enable_disable_button_index = welcome.append ("comet-128", _("Enable Comet"), _("Use Comet as the default editor for git commit messages."));
            }
            enable_disable_button = welcome.get_button_from_index (enable_disable_button_index);

            welcome.append ("help-faq", _("Help"), _("Having trouble? Get help and report issues."));
            welcome.set_size_request (560, 380);

            welcome.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        if (comet_is_enabled) {
                            disable_comet ();
                        } else {
                            enable_comet ();
                        }
                        create_layout ();
                    break;

                    case 1:
                        try {
                            AppInfo.launch_default_for_uri ("https://github.com/small-tech/comet#readme", null);
                        } catch (Error error) {
                            warning (error.message);
                        }
                    break;
                }
            });

            welcome.show_all ();
            grid.attach (welcome, 0, 1);
            enable_disable_button.grab_focus ();
        }

        private bool is_comet_enabled () {
            // Check if Comet is the default git editor and create the first option accordingly
            // (either to set Comet as the default editor or to restore the previously-set editor).
            string git_config_stdout;
            string git_config_stderr;
            int git_config_exit_status;

            // TODO: Also handle spawn without Flatpak so app functions properly
            // ===== when testing via task/run too.

            try {
                Process.spawn_command_line_sync (
                    "flatpak-spawn --host git config --global core.editor",
                    out git_config_stdout,
                    out git_config_stderr,
                    out git_config_exit_status
                );

                print (@"stdout: >$(git_config_stdout)<");
                print (@"stderr: $(git_config_stderr)");
                print (@"exit status: $(git_config_exit_status)");

                return (git_config_stdout.replace ("\n", "") == "flatpak run com.github.small_tech.comet");
            } catch (SpawnError error) {
                // TODO: Expose this error better.
                warning (error.message);
                return false;
            }
        }

        private bool enable_comet () {
            // TODO: Also handle spawn without Flatpak so app functions properly
            // ===== when testing via task/run too.

            var result = Posix.system ("flatpak-spawn --host git config --global core.editor \"flatpak run com.github.small_tech.comet\"");
            if (result == 0) {
                // Comet is enabled.
                comet_is_enabled = true;
            } else {
                // Comet configuration failed.
                print("Git configuration failed.\n");
            }
            return result == 0;
        }

        private bool disable_comet () {
            // TODO: Also handle spawn without Flatpak so app functions properly
            // ===== when testing via task/run too.

            // TODO: Do not harcode to Gnomit ;)
            var result = Posix.system ("flatpak-spawn --host git config --global core.editor \"flatpak run org.small_tech.Gnomit\"");
            if (result == 0) {
                // Comet is disabled.
                comet_is_enabled = false;
            } else {
                print("Git configuration failed.\n");
            }
            return result == 0;
        }

        // Changing the icon of a WelcomeButton doesn’t work currently so we can’t do this.
        // See https://github.com/elementary/granite/issues/530

        //  private void update_enable_disable_button () {
        //      // TODO: Remove repitition in title, description and icon from when first created.
        //      // TODO: Looks like setting the icon fails. Perhaps it’d be easier to just create the whole Welcome view again.
        //      // ===== Try that and see if it flickers or works.
        //      if (comet_is_enabled) {
        //          enable_disable_button.title = _("Disable Comet");
        //          enable_disable_button.description = _("Revert to using your previous editor for git commit messages.");
        //          enable_disable_button.icon = new Gtk.Image.from_icon_name ("comet-disable", Gtk.IconSize.DIALOG);
        //      } else {
        //          enable_disable_button.title = _("Enable Comet");
        //          enable_disable_button.description = _("Use Comet as the default editor for git commit messages.");
        //          enable_disable_button.icon = new Gtk.Image.from_icon_name ("comet-128", Gtk.IconSize.DIALOG);
        //      }
        //  }
    }
}
