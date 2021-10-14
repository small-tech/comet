namespace Comet {
    public class MainWindow : Comet.BaseWindow {
        // Model
        public Comet.Model model { get; private set; }

        // Widgets
        private Gtk.TextView comment_view;
        private Gtk.TextView message_view;
        private Gtk.Button commit_button;

        // Spell check
        private Gspell.TextView g_spell_text_view;

        // Buffers
        private Gtk.TextBuffer comment_view_buffer;
        private Gtk.TextBuffer message_view_buffer;

        // Highlighting
        private string HIGHLIGHT_BACKGROUND_TAG_NAME = "highlight-background";

        // TODO: Make this configurable.
        private int FIRST_LINE_CHARACTER_LIMIT = 69;

        private Gtk.TextTag highlight_background_tag;

        // Actions
        private const string ACTION_COMMIT = "action_commit";

        public MainWindow (Comet.Application application) {
            base (application);
            // Note: we would ideally be accepting the commit_message_file reference
            // ===== here, instead of accessing it via the app construct-only
            //       property in the create_layout () method, below but it does
            //       not seem possible in Vala.
            //       Neither setting a construct-time property or calling Object ()
            //       alongside base () works.
        }

        protected override void define_action_accelerators () {
            action_accelerators.set (ACTION_COMMIT, "<Control>Return");
        }

        protected override void create_layout () {
            // Save a local reference to the model for easier use.
            model = app.model;

            // Define action entries. These will be used by the base class
            // when setting up accelerators.
            ACTION_ENTRIES = {
                {ACTION_COMMIT, action_commit}
            };

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

            highlight_background_tag = new Gtk.TextTag (HIGHLIGHT_BACKGROUND_TAG_NAME);
            message_view_buffer.tag_table.add (highlight_background_tag);

            message_scrolled_window.add (message_view);

            Gtk.TextIter start_of_message;
            message_view_buffer.get_start_iter (out start_of_message);
            message_view_buffer.place_cursor (start_of_message);

            // Set up spell checking for the text view.
            g_spell_text_view = Gspell.TextView.get_from_gtk_text_view (message_view);
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

            cancel_button.clicked.connect (app.quit);
            commit_button.clicked.connect (save_commit_message_and_exit);

            validate_commit_button ();

            grid.attach (button_box, 0, 3);

            // Highlight colour.
            style_updated.connect (set_highlight_colour);
            message_view_buffer.changed.connect (highlight_text);
            message_view_buffer.paste_done.connect (highlight_text);

            // Exit via escape key.
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


        private void action_commit () {
            print ("MainWindow: Action commit");
            if (validate_commit_button ()) {
                print ("Commiting via action.");
                save_commit_message_and_exit ();
            }
        }


        private void save_commit_message_and_exit () {
            try {
                app.model.save ();
                app.quit ();
            } catch (FileError error) {
                // TODO: Handle this better.
                warning ("Could not save commit message.");
            }
        }


        private bool validate_commit_button () {
            var lines = app.model.message_buffer.text.strip ().split ("\n");
            var number_of_lines_in_message = lines.length;
            var commit_is_valid = number_of_lines_in_message > 0;
            commit_button.set_sensitive (commit_is_valid);

            return commit_is_valid;
        }


        private void set_highlight_colour () {
            // Set the overflow text background highlight colour based on the
            // colour of the foreground text.

            // Colour shade guide for Minty Rose: https://www.color-hex.com/color/ffe4e1
            var dark_foreground_highlight_colour = "#ffe4e1";  // minty rose
            var light_foreground_highlight_colour = "#4c4443"; // darker shade of minty rose
            string highlight_colour;
            var font_colour = g_spell_text_view.get_view().get_style_context().get_color(Gtk.StateFlags.NORMAL);

            // Luma calculation courtesy: https://stackoverflow.com/a/12043228
            var luma = 0.2126 * font_colour.red + 0.7152 * font_colour.green + 0.0722 * font_colour.blue; // ITU-R BT.709

            // As get_color() returns r/g/b values between 0 and 1, the luma calculation will
            // return values between 0 and 1 also.
            if (luma > 0.5) {
                // The foreground is light, use darker shade of original highlight colour.
                highlight_colour = light_foreground_highlight_colour;
            } else {
                // The foreground is dark, use original highlight colour.
                highlight_colour = dark_foreground_highlight_colour;
            }
            highlight_background_tag.background = highlight_colour;
        }


        public void highlight_text () {
            // Check first line length and highlight characters beyond the limit.
            var text = message_view_buffer.text;
            var lines = text.split ("\n");
            var first_line = lines[0];
            var first_line_length = first_line.length;

            // Get bounding iterators for the first line.
            Gtk.TextIter message_start_text_iterator;
            Gtk.TextIter message_end_text_iterator;
            Gtk.TextIter end_of_first_line_iterator;
            message_view_buffer.get_start_iter (out message_start_text_iterator);
            message_view_buffer.get_end_iter (out message_end_text_iterator);
            message_view_buffer.get_iter_at_offset (out end_of_first_line_iterator, first_line_length);

            // Start with a clean slate: remove any background highlighting on the
            // whole text. (We don’t do just the first line as someone might copy a
            // highlighted piece of the first line and paste it and we don’t want it
            // highlighted on subsequent lines if they do that.)
            message_view_buffer.remove_tag_by_name (HIGHLIGHT_BACKGROUND_TAG_NAME, message_start_text_iterator, message_end_text_iterator);

            // Highlight the overflow area, if any.
            if (first_line_length > FIRST_LINE_CHARACTER_LIMIT) {
                Gtk.TextIter start_of_overflow_iterator;
                message_view_buffer.get_iter_at_offset (out start_of_overflow_iterator, FIRST_LINE_CHARACTER_LIMIT);
                message_view_buffer.apply_tag (highlight_background_tag, start_of_overflow_iterator, end_of_first_line_iterator);
            }
        }
    }
}
