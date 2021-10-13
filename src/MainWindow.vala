namespace Comet {
    public class MainWindow : Comet.BaseWindow {
        // Model
        public Comet.Model model { get; private set; }

        // Widgets
        private Gtk.TextView comment_view;
        private Gtk.TextBuffer comment_view_buffer;
        private Gtk.TextView message_view;
        private Gtk.TextBuffer message_view_buffer;

        public MainWindow (Comet.Application application) {
            base (application);
            // Note: we would ideally be accepting the commit_message_file reference
            // ===== here, instead of accessing it via the app construct-only
            //       property in the create_layout () method, below but it does
            //       not seem possible in Vala.
            //       Neither setting a construct-time property or calling Object ()
            //       alongside base () works.
        }

        protected override void create_layout () {
            // Save a local reference to the model for easier use.
            model = app.model;

            var title_string = @"Comet: $(model.action) ($(model.detail))";
            title = title_string;           // Window title, used in task switcher, etc.
            toolbar.title = title_string;   // Toolbar title, displayed in app.

            // Create scrollable text view for the message.
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
            message_view_buffer.insert_text (ref message_view_iterator, model.message, -1);
            message_scrolled_window.add (message_view);

            Gtk.TextIter start_of_message;
            message_view_buffer.get_start_iter (out start_of_message);
            message_view_buffer.place_cursor (start_of_message);

            grid.attach (message_scrolled_window, 0, 1);

            // Create simple text view for comment.
            comment_view = new Gtk.TextView ();
            comment_view.margin = 12;
            comment_view_buffer = comment_view.get_buffer ();

            Gtk.TextIter comment_view_iterator;
            comment_view_buffer.get_start_iter (out comment_view_iterator);
            comment_view_buffer.insert_markup (ref comment_view_iterator, model.comment, -1);

            grid.attach (comment_view, 0, 2);

            // Add the action buttons.
            var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            button_box.margin = 12;
            button_box.layout_style = Gtk.ButtonBoxStyle.EDGE;
            var cancel_button = new Gtk.Button.with_label (_("Cancel"));
            var commit_button = new Gtk.Button.with_label (_("Commit"));
            button_box.add (cancel_button);
            button_box.add (commit_button);

            grid.attach (button_box, 0, 3);
        }
    }
}
