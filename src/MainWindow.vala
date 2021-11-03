namespace Comet {
    public class MainWindow : Comet.BaseWindow {
        // Model
        public Comet.Model model { get; private set; }

        // Widgets
        private Gtk.TextView comment_view;
        private Gtk.TextView message_view;
        private Gtk.Button commit_button;
        private Gtk.Overlay overlay;
        private Granite.Widgets.OverlayBar overlay_bar;

        // Spell check
        private Gspell.TextView g_spell_text_view;

        // Buffers
        private Gtk.TextBuffer comment_view_buffer;
        private Gtk.TextBuffer message_view_buffer;

        // Highlighting
        private string HIGHLIGHT_BACKGROUND_TAG_NAME = "highlight-background";
        private string UNDERLINE_COLOUR_TAG_NAME = "underline-colour";

        // TODO: Make this configurable.
        private int FIRST_LINE_CHARACTER_LIMIT = 69;

        private Gtk.TextTag highlight_background_tag;
        private Gtk.TextTag underline_colour_tag;

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

            // Create an overlay container.
            // (We will add an overlay bar to this lazily to show
            // the number of characters left as the person gets closer to the
            // limit.)
            overlay = new Gtk.Overlay ();

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

            underline_colour_tag = new Gtk.TextTag (UNDERLINE_COLOUR_TAG_NAME);
            var red = Gdk.RGBA ();
            red.parse ("#ff5555");
            underline_colour_tag.underline_rgba = red;
            //  underline_colour_tag.set_priority (message_view_buffer.get_tag_table ().get_size ());
            message_view_buffer.tag_table.add (underline_colour_tag);

            // Original dracula background colour: #282a36
            // Darker dracula background colour: #121220
            var dracula_theme = """
                textview text {
                    color: #f8f8f2;
                    background-color: #282a36;
                }

                textview selection {
                    color: #f8f8f2;
                    background-color: #44475a;
                }
            """;
            var css_provider = new Gtk.CssProvider ();
            css_provider.load_from_data (dracula_theme, -1);
            message_view.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


            highlight_background_tag = new Gtk.TextTag (HIGHLIGHT_BACKGROUND_TAG_NAME);
            message_view_buffer.tag_table.add (highlight_background_tag);

            message_scrolled_window.add (message_view);

            Gtk.TextIter start_of_message;
            message_view_buffer.get_start_iter (out start_of_message);
            message_view_buffer.place_cursor (start_of_message);

            // Set up spell checking for the text view.
            g_spell_text_view = Gspell.TextView.get_from_gtk_text_view (message_view);
            g_spell_text_view.basic_setup ();

            overlay.add (message_scrolled_window);

            grid.attach (overlay, 0, 1);

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
            //  message_view_buffer.delete_range.connect (highlight_text);
            message_view_buffer.notify["cursor-position"].connect (highlight_text);

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

            // Validate the commit button whenever the person updates the message.
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
            var dark_foreground_highlight_colour = "#ff5555";  // minty rose
            var light_foreground_highlight_colour = "#ff5555"; // darker shade of minty rose
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
            highlight_background_tag.foreground = "#282a36";
        }


        public void highlight_text () {
            // Check first line length and highlight characters beyond the limit.
            var text = message_view_buffer.text;
            var lines = text.split ("\n");
            var first_line = lines[0];

            if (first_line == null) {
                // No characters in message; nothing to do.
                return;
            }

            //
            // The following code does the equivalent of firstLine.characters.count in Swift
            // because it you don’t enjoy the pain why are you even using Gtk/Vala amirite? *smh*
            //
            Gtk.TextIter glyph_count_iter;
            message_view_buffer.get_start_iter (out glyph_count_iter);

            var first_line_length = 0;
            while (!glyph_count_iter.ends_line () && !glyph_count_iter.is_end ()) {
                first_line_length++;

                // We have to forward the cursor position (not the character)
                // in order to count Unicode grapheme clusters (e.g., 🧟‍♀️️, as a single character.
                glyph_count_iter.forward_cursor_position ();
            }

            var cursor_position = message_view_buffer.cursor_position;

            Gtk.TextIter cursor_position_iter;
            message_view_buffer.get_iter_at_offset (out cursor_position_iter, cursor_position);

            // We have to do all comparisons using iterators.
            var characters_left = FIRST_LINE_CHARACTER_LIMIT - first_line_length;
            if ((characters_left < 15) && (characters_left > -1) && cursor_position_iter.compare(glyph_count_iter) <= 0) {
                if (overlay_bar == null) {
                    // Create overlay bar to display hint about number of characters left.
                    overlay_bar = new Granite.Widgets.OverlayBar (overlay);
                    overlay.show_all ();
                }
                overlay_bar.label = _(@"$(characters_left) characters left on first line");
                overlay_bar.visible = true;
            } else {
                if (overlay_bar != null) {
                    overlay_bar.visible = false;
                }
            }

            // Get bounding iterators for the first line.
            Gtk.TextIter message_start_text_iterator;
            Gtk.TextIter message_end_text_iterator;
            Gtk.TextIter end_of_first_line_iterator;
            message_view_buffer.get_start_iter (out message_start_text_iterator);
            message_view_buffer.get_end_iter (out message_end_text_iterator);
            message_view_buffer.get_iter_at_line (out end_of_first_line_iterator, 0);
            end_of_first_line_iterator.forward_to_line_end ();

            // Start with a clean slate: remove any background highlighting on the
            // whole text. (We don’t do just the first line as someone might copy a
            // highlighted piece of the first line and paste it and we don’t want it
            // highlighted on subsequent lines if they do that.)
            message_view_buffer.remove_tag_by_name (HIGHLIGHT_BACKGROUND_TAG_NAME, message_start_text_iterator, message_end_text_iterator);
            message_view_buffer.remove_tag_by_name (UNDERLINE_COLOUR_TAG_NAME, message_start_text_iterator, message_end_text_iterator);
            message_view_buffer.apply_tag (underline_colour_tag, message_start_text_iterator, message_end_text_iterator);
            underline_colour_tag.set_priority (message_view_buffer.get_tag_table ().get_size () - 1);

            // Highlight the overflow area, if any.
            if (first_line_length > FIRST_LINE_CHARACTER_LIMIT) {
                Gtk.TextIter start_of_overflow_iterator;
                message_view_buffer.get_start_iter (out start_of_overflow_iterator);
                start_of_overflow_iterator.forward_cursor_positions (FIRST_LINE_CHARACTER_LIMIT);
                message_view_buffer.apply_tag (highlight_background_tag, start_of_overflow_iterator, end_of_first_line_iterator);
            }
        }
    }
}
