namespace Comet {
    public class WelcomeWindow : Comet.BaseWindow {

        private bool comet_is_enabled;
        private Granite.Widgets.WelcomeButton enable_disable_button;
        private Comet.Widgets.Welcome welcome;

        private string GIT_CONFIG_GLOBAL_CORE_EDITOR = "git config --global core.editor";
        private string FLATPAK_SPAWN_HOST = "flatpak-spawn --host";
        private string FLATPAK_RUN = "flatpak run";

        private string? current_editor {
            owned get {
                string git_config_stdout;
                string git_config_stderr;
                int git_config_exit_status;

                var command = Application.is_running_as_flatpak ?
                    @"$(FLATPAK_SPAWN_HOST) $(GIT_CONFIG_GLOBAL_CORE_EDITOR)" :
                    GIT_CONFIG_GLOBAL_CORE_EDITOR;

                try {
                    Process.spawn_command_line_sync (
                        command,
                        out git_config_stdout,
                        out git_config_stderr,
                        out git_config_exit_status
                    );

                    return git_config_stdout.replace ("\n", "");
                } catch (SpawnError error) {
                    // TODO: Expose this error better.
                    warning (error.message);
                    return null;
                }
            }
        }


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
            var comet_path = Application.is_running_as_flatpak ?
                @"$(FLATPAK_RUN) $(Application.flatpak_id)" :
                Application.binary_path;

            return current_editor == comet_path;
        }


        private bool enable_comet () {
            var command = Application.is_running_as_flatpak ?
                @"$(FLATPAK_SPAWN_HOST) $(GIT_CONFIG_GLOBAL_CORE_EDITOR) \"$(FLATPAK_RUN) $(Application.flatpak_id)\""
                : @"$(GIT_CONFIG_GLOBAL_CORE_EDITOR) $(Application.binary_path)";

            var result = Posix.system (command);
            if (result == 0) {
                // Comet is enabled.
                comet_is_enabled = true;
            } else {
                // Comet configuration failed.
                // TODO: handle better.
                print("Git configuration failed.\n");
            }
            return result == 0;
        }


        private bool disable_comet () {
            // TODO: Do not harcode to Gnomit ;)
            var command = Application.is_running_as_flatpak ?
                @"$(FLATPAK_SPAWN_HOST) $(GIT_CONFIG_GLOBAL_CORE_EDITOR) \"$(FLATPAK_RUN) org.small_tech.Gnomit\""
                : @"$(GIT_CONFIG_GLOBAL_CORE_EDITOR) \"flatpak run org.small_tech.Gnomit\"";

            var result = Posix.system (command);
            if (result == 0) {
                // Comet is disabled.
                comet_is_enabled = false;
            } else {
                // TODO: handle better.
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
