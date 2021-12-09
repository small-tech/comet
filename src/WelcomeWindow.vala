namespace Comet {
    public class WelcomeWindow : Comet.BaseWindow {

        private bool comet_is_enabled { get; set; }

        private Granite.Widgets.WelcomeButton enable_disable_button;
        private Granite.Widgets.Welcome welcome;
        private Gtk.Grid status_grid;

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
                // This is the first time this view is being shown.
                if (!comet_is_enabled) {
                    ask_permission_to_enable_comet ();
                }
            } else {
                // This is not the first time the view is being created.
                // Remove the old view.
                grid.remove(welcome);
                grid.remove(status_grid);
            }

            welcome = new Granite.Widgets.Welcome (
                "Comet",
                _("Write better Git commit messages.")
            );

            int enable_disable_button_index;
            if (comet_is_enabled) {
                enable_disable_button_index = welcome.append ("comet-disable", _("Disable Comet"), _("Revert to using your previous editor for Git commit messages."));
            } else {
                enable_disable_button_index = welcome.append ("comet-128", _("Enable Comet"), _("Use Comet as the default editor for Git commit messages."));
            }
            enable_disable_button = welcome.get_button_from_index (enable_disable_button_index);

            // Request a specific width so the whole interface does not
            // jump around when we toggle it.
            enable_disable_button.width_request = 460;

            welcome.append ("comet-help", _("Help"), _("Having trouble? Get help and report issues."));
            welcome.set_size_request (540, 300);

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

            status_grid = new Gtk.Grid ();
            status_grid.orientation = Gtk.Orientation.VERTICAL;
            status_grid.halign = Gtk.Align.CENTER;

            // Insert the status text into the view.
            var status_message = comet_is_enabled ?
                _("Comet is enabled as your editor for Git commit messages.")
                : _("Comet is disabled.");

            var status_icon_name = comet_is_enabled ? "process-completed" : "process-stop";

            var status_label = new Gtk.Label (status_message);
            status_label.justify = Gtk.Justification.LEFT;
            status_label.wrap = true;
            status_label.wrap_mode = Pango.WrapMode.WORD;
            status_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            var status_icon = new Gtk.Image.from_icon_name (status_icon_name, Gtk.IconSize.LARGE_TOOLBAR);
            status_icon.margin_top = 8;
            status_icon.margin_bottom = 8;

            var status_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            status_box.add (status_icon);
            status_box.add (status_label);

            status_grid.add (status_box);

            status_grid.show_all ();
            welcome.show_all ();

            grid.attach (welcome, 0, 1);
            grid.attach (status_grid, 0, 2);

            // Necessary for the “toggle” to maintain focus.
            enable_disable_button.grab_focus ();
        }


        private void ask_permission_to_enable_comet () {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Use Comet as your Git commit message editor?"),
                _("This will update your Git configuration for you."),
                "dialog-question",
                Gtk.ButtonsType.NONE
            );
            message_dialog.badge_icon = new ThemedIcon("comet-128");

            var no_button = new Gtk.Button.with_label (_("No"));
            message_dialog.add_action_widget (no_button, Gtk.ResponseType.NO);

            var yes_button = new Gtk.Button.with_label (_("Yes"));
            yes_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            message_dialog.add_action_widget (yes_button, Gtk.ResponseType.YES);
            yes_button.can_default = true;
            yes_button.grab_default ();

            message_dialog.show_all ();

            message_dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.YES) {
                    enable_comet ();
                    message_dialog.close ();
                } else {
                    message_dialog.close ();
                }
            });

            message_dialog.run ();
        }



        private bool is_comet_enabled () {
            var comet_path = Application.is_running_as_flatpak ?
                @"$(FLATPAK_RUN) $(Application.flatpak_id)" :
                Application.binary_path;

            return current_editor == comet_path;
        }


        private bool enable_comet () {
            Comet.saved_state.set("previous-editor", "s", current_editor);

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
            string previous_editor;
            Comet.saved_state.get ("previous-editor", "s", out previous_editor);

            var command = Application.is_running_as_flatpak ?
                @"$(FLATPAK_SPAWN_HOST) $(GIT_CONFIG_GLOBAL_CORE_EDITOR) \"$(previous_editor)\""
                : @"$(GIT_CONFIG_GLOBAL_CORE_EDITOR) \"$(previous_editor)\"";

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
        //          enable_disable_button.description = _("Revert to using your previous editor for Git commit messages.");
        //          enable_disable_button.icon = new Gtk.Image.from_icon_name ("comet-disable", Gtk.IconSize.DIALOG);
        //      } else {
        //          enable_disable_button.title = _("Enable Comet");
        //          enable_disable_button.description = _("Use Comet as the default editor for Git commit messages.");
        //          enable_disable_button.icon = new Gtk.Image.from_icon_name ("comet-128", Gtk.IconSize.DIALOG);
        //      }
        //  }
    }
}
