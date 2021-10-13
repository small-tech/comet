namespace Comet {
    public class MainWindow : Comet.BaseWindow {
        // Model
        public Comet.Model model { get; private set; }

        // Widgets
        private Gtk.TextView comment_view;
        private Gtk.TextView message_view;
        private Gtk.Button commit_button;

        // Buffers
        private Gtk.TextBuffer comment_view_buffer;
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
            message_view.input_hints =
                Gtk.InputHints.SPELLCHECK |
                Gtk.InputHints.WORD_COMPLETION |
                Gtk.InputHints.EMOJI |
                Gtk.InputHints.UPPERCASE_SENTENCES;
            message_view.set_buffer (model.message_buffer);
            message_view_buffer = message_view.get_buffer ();

            message_scrolled_window.add (message_view);

            Gtk.TextIter start_of_message;
            message_view_buffer.get_start_iter (out start_of_message);
            message_view_buffer.place_cursor (start_of_message);

            // Set up spell checking for the text view.
            var g_spell_text_view = Gspell.TextView.get_from_gtk_text_view (message_view);
            g_spell_text_view.basic_setup ();

            grid.attach (message_scrolled_window, 0, 1);

            // Create simple text view for comment.
            comment_view = new Gtk.TextView ();
            comment_view.margin = 12;
            comment_view.buffer = model.comment_buffer;
            comment_view_buffer = comment_view.get_buffer ();

            // Mark the comment area as non-editable.
            comment_view.editable = false;

            grid.attach (comment_view, 0, 2);

            // Add the action buttons.
            var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            button_box.margin = 12;
            button_box.layout_style = Gtk.ButtonBoxStyle.EDGE;
            var cancel_button = new Gtk.Button.with_label (_("Cancel"));

            commit_button = new Gtk.Button.with_label (_("Commit"));

            button_box.add (cancel_button);
            button_box.add (commit_button);

            cancel_button.clicked.connect (() => {
                app.quit ();
            });

            commit_button.clicked.connect (() => {
                try {
                    model.save ();
                    app.quit ();
                } catch (FileError error) {
                    // TODO: Handle this better.
                    warning ("Could not save commit message.");
                }
            });

            validate_commit_button ();

            grid.attach (button_box, 0, 3);

            // Exit via escape key.
            //  add_events (Gdk.EventMask.KEY_PRESS_MASK);
            key_press_event.connect ((widget, event) => {
                uint keyValue;
                event.get_keyval (out keyValue);
                if (keyValue == Gdk.Key.Escape) {
                    app.quit();
                    return true;
                }
                return false;
            });


            // Handle message buffer signals.

            message_view_buffer.end_user_action.connect (() => {
                validate_commit_button ();
            });
        }

        private void validate_commit_button () {
            var lines = app.model.message_buffer.text.strip ().split ("\n");
            var number_of_lines_in_message = lines.length;
            commit_button.set_sensitive (number_of_lines_in_message > 0);
        }
    }
}
