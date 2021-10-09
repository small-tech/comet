namespace Comet.Widgets {
    public class Welcome : Granite.Widgets.Welcome {

        public string status { get; construct; }

        public Welcome (string title_text, string subtitle_text, string status_text) {
            Object (title: title_text, subtitle: subtitle_text, status: status_text);
        }

        construct {
            var status_grid = new Gtk.Grid ();
            status_grid.orientation = Gtk.Orientation.VERTICAL;
            status_grid.halign = Gtk.Align.CENTER;
            status_grid.row_spacing = 12;
            status_grid.margin_top = 24;
            status_grid.margin_bottom = 12;

            // Insert the status text into the view.
            var status_label = new Gtk.Label (status);
            status_label.justify = Gtk.Justification.LEFT;
            status_label.wrap = true;
            status_label.wrap_mode = Pango.WrapMode.WORD;
            status_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            status_label.margin_right = 12;

            var status_icon = new Gtk.Image.from_icon_name ("process-completed", Gtk.IconSize.DND);
            status_icon.margin_left = 12;
            status_icon.margin_top = 12;
            status_icon.margin_bottom = 12;

            var status_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            status_box.add (status_icon);
            status_box.add (status_label);

            // Make the status box display as a rounded card to further
            // differentiate it from the list of actionable choices.
            var status_box_style_context = status_box.get_style_context ();
            status_box_style_context.add_class (Granite.STYLE_CLASS_CARD);
            status_box_style_context.add_class (Granite.STYLE_CLASS_ROUNDED);

            status_grid.add (status_box);

            var baseGrid = (Gtk.Grid) get_child ();
            baseGrid.insert_row (2);
            baseGrid.attach (status_grid, 0, 2);
        }
    }
}
