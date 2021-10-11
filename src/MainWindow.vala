namespace Comet {
    public class MainWindow : Comet.BaseWindow {
        // Widgets
        private Gtk.TextView comment_view;
        private Gtk.TextBuffer comment_view_buffer;
        private Gtk.TextView message_view;
        private Gtk.TextBuffer message_view_buffer;

        public MainWindow (Comet.Application application) {
            base (application);
        }
        //      Object (
        //          // We must set the inherited application property for Hdy.ApplicationWindow
        //          // to initialise properly. However, this is not a set-type property (get; set;)
        //          // so the assignment is made after construction, which means that we cannot
        //          // reference the application during the construct method. This is why we also
        //          // declare a property called app that is construct-type (get; construct;) which
        //          // is assigned before the constructors are run.
        //          //
        //          // So use the app property when referencing the application instance from
        //          // the constructors. Anywhere else, they can be used interchangably.
        //          app: application,
        //          application: application,                    // DON’T use in constructors; won’t have been assigned yet.
        //          height_request: 420,
        //          width_request: 420,
        //          hide_titlebar_when_maximized: true,          // FIXME: This does not seem to have an effect. Why not?
        //          icon_name: "com.github.small_tech.comet"
        //      );
        //  }

        //  // This constructor will be called every time an instance of this class is created.
        //  construct {
        //      // Create window layout.
        //      create_layout ();

        //      // Make all widgets (the interface) visible.
        //      show_all ();
        //  }

        // Layout.

        protected override void create_layout () {
            // Add a scrollable text view for the message.
            var message_scrolled_window = new Gtk.ScrolledWindow (null, null);
            message_scrolled_window.get_style_context ().add_class (Granite.STYLE_CLASS_TERMINAL);
            message_scrolled_window.vexpand = true;

            message_view = new Gtk.TextView ();
            message_view.get_style_context ().add_class (Granite.STYLE_CLASS_TERMINAL);
            message_view.wrap_mode = Gtk.WrapMode.WORD;
            message_view.margin = 12;
            message_view_buffer = message_view.get_buffer ();

            Gtk.TextIter message_view_iterator;
            message_view_buffer.get_start_iter (out message_view_iterator);

            message_scrolled_window.add (message_view);

            grid.attach (message_scrolled_window, 0, 1);

            // Add a scrollable text view for the comment.
            //  var comment_scrolled_window = new Gtk.ScrolledWindow (null, null);
            //  comment_scrolled_window.vexpand = true;

            comment_view = new Gtk.TextView ();
            comment_view.margin = 12;
            comment_view_buffer = comment_view.get_buffer ();

            Gtk.TextIter comment_view_iterator;
            comment_view_buffer.get_start_iter (out comment_view_iterator);
            comment_view_buffer.insert_markup (ref comment_view_iterator, app.comment, -1);

            //  comment_scrolled_window.add (comment_view);

            grid.attach (comment_view, 0, 2);

            // Add the action buttons.
            var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            button_box.margin = 12;
            //  button_box.spacing = 6;
            button_box.layout_style = Gtk.ButtonBoxStyle.EDGE;
            var cancel_button = new Gtk.Button.with_label (_("Cancel"));
            var commit_button = new Gtk.Button.with_label (_("Commit"));
            button_box.add (cancel_button);
            button_box.add (commit_button);

            grid.attach (button_box, 0, 3);
        }
    }
}
