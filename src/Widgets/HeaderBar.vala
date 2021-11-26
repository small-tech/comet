namespace Comet.Widgets {
    public class HeaderBar : Hdy.HeaderBar {

        private Gtk.MenuButton app_menu;

        public HeaderBar () {
            Object (
                title: _("Comet"),
                has_subtitle: false,
                show_close_button: true,
                hexpand: true
            );
        }

        construct {
            var initial_line_limit = Comet.saved_state.get_int(Constants.Names.Settings.FIRST_LINE_CHARACTER_LIMIT);
            var line_length_adjustment = new Gtk.Adjustment (initial_line_limit, /* min */ 50, /* max */ 133, 1, 1, 1);
            var line_length_numerical_spinner = new Gtk.SpinButton (line_length_adjustment, 1.0, 0);

            var line_length_label = new Gtk.Label (_("First line character limit"));

            var line_length_limit = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            line_length_limit.add(line_length_label);
            line_length_limit.add(line_length_numerical_spinner);

            line_length_numerical_spinner.value_changed.connect (() => {
                var new_line_length = (int) line_length_numerical_spinner.value;
                Comet.saved_state.set_int (Constants.Names.Settings.FIRST_LINE_CHARACTER_LIMIT, new_line_length);
            });

            var dogmatic_limit = new Gtk.Button.with_label (_("Dogmatic (50)"));
            dogmatic_limit.margin_top = 6;

            var github_limit = new Gtk.Button.with_label (_("GitHub truncation (72)"));
            github_limit.margin_top = 3;

            var gitlab_limit = new Gtk.Button.with_label (_("GitLab truncation (100)"));
            gitlab_limit.margin_top = 3;

            dogmatic_limit.clicked.connect (() => {
                line_length_numerical_spinner.value = 50;
            });

            github_limit.clicked.connect (() => {
                line_length_numerical_spinner.value = 72;
            });

            gitlab_limit.clicked.connect (() => {
                line_length_numerical_spinner.value = 100;
            });

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.attach (line_length_limit, 0, 0, 1, 1);
            menu_grid.attach (dogmatic_limit, 0, 1, 1, 1);
            menu_grid.attach (github_limit, 0, 2, 1, 1);
            menu_grid.attach (gitlab_limit, 0, 3, 1, 1);
            menu_grid.show_all ();

            var menu = new Gtk.Popover (null);
            menu.add (menu_grid);

            app_menu = new Gtk.MenuButton ();
            app_menu.image = new Gtk.Image.from_icon_name ("emblem-system", Gtk.IconSize.SMALL_TOOLBAR);
            app_menu.tooltip_text = _("Settings");
            app_menu.popover = menu;

            pack_end(app_menu);

            show_all ();
        }

        public void show_settings () {
            app_menu.clicked ();
        }
    }
}
