namespace Comet.Widgets {
    public class HeaderBar : Hdy.HeaderBar {
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
            var line_length_adjustment = new Gtk.Adjustment (initial_line_limit, /* min */ 50, /* max */ 121, 1, 1, 1);
            var line_length_numerical_spinner = new Gtk.SpinButton (line_length_adjustment, 1.0, 0);

            var line_length_label = new Gtk.Label (_("Line limit"));

            var line_length_limit = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            line_length_limit.add(line_length_label);
            line_length_limit.add(line_length_numerical_spinner);

            line_length_numerical_spinner.value_changed.connect (() => {
                var new_line_length = (int) line_length_numerical_spinner.value;
                Comet.saved_state.set_int (Constants.Names.Settings.FIRST_LINE_CHARACTER_LIMIT, (int) line_length_numerical_spinner.value);
            });

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.width_request = 200;
            menu_grid.attach (line_length_limit, 0, 0, 1, 1);
            menu_grid.show_all ();

            var menu = new Gtk.Popover (null);
            menu.add(menu_grid);

            var app_menu = new Gtk.MenuButton ();
            app_menu.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
            app_menu.tooltip_text = _("Settings");
            app_menu.popover = menu;

            pack_end(app_menu);

            show_all ();
        }
    }
}
