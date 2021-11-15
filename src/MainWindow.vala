namespace Comet {
    public class MainWindow : Comet.BaseWindow {
        // Model
        public Comet.Model model { get; private set; }

        // Settings
        Granite.Settings granite_settings;
        bool is_dark_mode;
        int first_line_character_limit;

        // Widgets
        private Gtk.TextView comment_view;
        private Gtk.ScrolledWindow message_scrolled_window;
        private Gtk.TextView message_view;
        private Gtk.ButtonBox button_box;
        private Gtk.Button commit_button;
        private Gtk.Overlay overlay;
        private Gtk.InfoBar keyboard_shortcut_tip;
        private Granite.Widgets.OverlayBar overlay_bar;

        // Style providers
        private Gtk.CssProvider base_styles_css_provider;
        private Gtk.CssProvider comment_view_css_provider;
        private Gtk.CssProvider keyboard_shortcut_tip_css_provider;

        // Spell check
        private Gspell.TextView g_spell_text_view;

        // Buffers
        private Gtk.TextBuffer comment_view_buffer;
        private Gtk.TextBuffer message_view_buffer;

        // Highlighting
        private string HIGHLIGHT_BACKGROUND_TAG_NAME = "highlight-background";
        private string UNDERLINE_COLOUR_TAG_NAME = "underline-colour";

        private Gtk.TextTag highlight_background_tag;
        private Gtk.TextTag underline_colour_tag;

        // Colours
        private string message_foreground_colour;
        private string message_background_colour;

        // Actions
        private const string ACTION_COMMIT = "action_commit";

        // Accelerators
        private const string COMMIT_ACCELERATOR = "<Control>Return";
        private const string CANCEL_ACCELERATOR = "Escape";
        private const string QUIT_ACCELERATOR = "<Control>Q";


        public MainWindow (Comet.Application application) {
            base (application);
            // Note: we would ideally be accepting the commit_message_file reference
            // ===== here, instead of accessing it via the app construct-only
            //       property in the create_layout () method, below but it does
            //       not seem possible in Vala.
            //       Neither setting a construct-time property or calling Object ()
            //       alongside base () works.
            update_first_line_character_limit ();
            Comet.saved_state.changed.connect (() => {
                update_first_line_character_limit ();
            });

            // For testing only. To reset the keyboard shortcut tip.
            // Comet.saved_state.set_boolean (Constants.Names.Settings.SHOW_KEYBOARD_SHORTCUT_TIP, true);
        }


        protected override void define_action_accelerators () {
            action_accelerators.set (ACTION_COMMIT, COMMIT_ACCELERATOR);
        }


        protected override void create_layout () {
            // Save a local reference to the model for easier use.
            model = app.model;

            // Define action entries. These will be used by the base class
            // when setting up accelerators.
            ACTION_ENTRIES = {
                {ACTION_COMMIT, action_commit}
            };

            // Note: app name in title string should not be translated.
            // The action and detail will already be localised by git.
            var title_string = @"Comet: $(model.action) ($(model.detail))";
            title = title_string;           // Window title, used in task switcher, etc.
            toolbar.title = title_string;   // Toolbar title, displayed in app.

            var grid_vertical_position = 1;

            // Create an overlay container.
            // (We will add an overlay bar to this lazily to show
            // the number of characters left as the person gets closer to the
            // limit.)
            overlay = new Gtk.Overlay ();

            // Create scrollable text view for the message.
            message_scrolled_window = new Gtk.ScrolledWindow (null, null);
            message_scrolled_window.vexpand = true;

            message_view = new Gtk.TextView ();
            message_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            message_view.margin = 12;
            message_view.input_hints =
                Gtk.InputHints.SPELLCHECK |
                Gtk.InputHints.WORD_COMPLETION |
                Gtk.InputHints.EMOJI |
                Gtk.InputHints.UPPERCASE_SENTENCES;
            message_view.set_buffer (model.message_buffer);
            message_view_buffer = message_view.get_buffer ();

            message_view.monospace = true;

            highlight_background_tag = new Gtk.TextTag (HIGHLIGHT_BACKGROUND_TAG_NAME);
            message_view_buffer.tag_table.add (highlight_background_tag);

            message_scrolled_window.add (message_view);

            Gtk.TextIter start_of_message;
            message_view_buffer.get_start_iter (out start_of_message);
            message_view_buffer.place_cursor (start_of_message);

            // Set up spell checking for the text view.
            g_spell_text_view = Gspell.TextView.get_from_gtk_text_view (message_view);
            g_spell_text_view.basic_setup ();

            // Add a tag that we’ll use to override the gspell underline colour.
            underline_colour_tag = new Gtk.TextTag (UNDERLINE_COLOUR_TAG_NAME);
            //  underline_colour_tag.set_priority (message_view_buffer.get_tag_table ().get_size ());
            message_view_buffer.tag_table.add (underline_colour_tag);

            overlay.add (message_scrolled_window);

            // Ensure that the editor view is always at least as large
            // as it was on first launch with a regular commit (with about
            // 5/6 lines of text visible) so that a long comment (e.g., a rebase)
            // doesn’t squeeze it down to a single line.
            message_scrolled_window.set_size_request (540, 130);

            grid.attach (overlay, 0, grid_vertical_position);
            grid_vertical_position++;

            // Display an information bar to teach the person the keyboard shortcuts for
            // commit and cancel until the person either dismisses it or until
            // they actually use one of the accelerators.
            if (Comet.saved_state.get_boolean (Constants.Names.Settings.SHOW_KEYBOARD_SHORTCUT_TIP)) {
                keyboard_shortcut_tip = new Gtk.InfoBar ();
                keyboard_shortcut_tip.message_type = Gtk.MessageType.INFO;
                keyboard_shortcut_tip.add_button (_("Hide tip"), Gtk.ResponseType.CLOSE);
                keyboard_shortcut_tip.response.connect (() => {
                    hide_keyboard_shortcut_tip ();
                });


                var content_area = keyboard_shortcut_tip.get_content_area ();

                var commit_tip_markup = Granite.markup_accel_tooltip ({COMMIT_ACCELERATOR}, _("Commit"));
                var cancel_tip_markup = Granite.markup_accel_tooltip ({CANCEL_ACCELERATOR}, _("Cancel"));

                var instructions_label = new Gtk.Label (_("Use keyboard shortcuts to improve your workflow."));
                content_area.add (instructions_label);

                var commit_shortcut_tip_label = new Gtk.Label (null);
                commit_shortcut_tip_label.set_markup (commit_tip_markup);
                content_area.add (commit_shortcut_tip_label);

                var cancel_shortcut_tip_label = new Gtk.Label (null);
                cancel_shortcut_tip_label.set_markup (cancel_tip_markup);
                content_area.add (cancel_shortcut_tip_label);

                grid.attach (keyboard_shortcut_tip, 0, grid_vertical_position);
                grid_vertical_position++;
            }

            // Create simple text view for comment.
            comment_view = new Gtk.TextView ();
            comment_view.margin = 12;
            comment_view.buffer = model.comment_buffer;
            comment_view_buffer = comment_view.get_buffer ();

            // Mark the comment area as non-editable.
            comment_view.editable = false;

            grid.attach (comment_view, 0, grid_vertical_position);
            grid_vertical_position++;

            // Add the action buttons.
            button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            button_box.layout_style = Gtk.ButtonBoxStyle.EDGE;
            var cancel_button = new Gtk.Button.with_label (_("Cancel"));
            cancel_button.margin = 12;

            commit_button = new Gtk.Button.with_label (_("Commit"));
            commit_button.margin = 12;

            button_box.add (cancel_button);
            button_box.add (commit_button);

            // Note: it’s OK to connect the cancel button directly to app.quit
            // as we don’t need to wait for anything (unlike use of the keyboard
            // accelerators for quit and commit which may have to wait for the
            // size of the window to change and be persisted in case the keyboard
            // accelerator tip was showing).
            cancel_button.clicked.connect (app.quit);
            commit_button.clicked.connect (save_commit_message_and_exit);

            validate_commit_button ();

            grid.attach (button_box, 0, grid_vertical_position);
            grid_vertical_position++;

            // Handle colour scheme.
            granite_settings = Granite.Settings.get_default ();

            // Listen for changes in person’s color scheme settings
            // and update color scheme of app accordingly.
            granite_settings.notify["prefers-color-scheme"].connect (() => {
                // I can’t seem to connect this signal to the update_styles method
                // directly and, if I invoke it in a closure, I can’t seem to
                // specify that the closure should throw so this is a hack.
                // If anyone knows of a better way to handle this, please open an issue.
                try {
                    update_styles();
                } catch (Error error) {
                    assert_not_reached ();
                }
            });

            // Ditto: I can’t specify that the create_layout method throws without
            // changing the base class.
            try {
                update_styles();
            } catch (Error error) {
                assert_not_reached ();
            }

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
                    hide_keyboard_shortcut_tip ();
                    quit_on_future_stack_frame ();
                    return true;
                }
                return false;
            });

            // Validate the commit button whenever the person updates the message.
            message_view_buffer.end_user_action.connect (() => {
                validate_commit_button ();
            });

            message_view.grab_focus ();
        }

        private void quit_on_future_stack_frame () {
            // Carry out the quit on a future stack frame to give
            // the window time to resize after hiding the shortcut
            // tip so window is correctly sized when we next launch.
            Timeout.add (0, () => {
                app.quit ();

                // Returning false here will ensure this closure
                // is called just once.
                return false;
            });
        }


        // Update styles. Is called at start and anytime the colour scheme changes.
        private void update_styles () throws GLib.Error {
            is_dark_mode = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

            message_foreground_colour = is_dark_mode ? Constants.Colours.SILVER_100 : Constants.Colours.BLACK_700;
            message_background_colour = is_dark_mode ? Constants.Colours.BLACK_700 : Constants.Colours.SILVER_100;
            var comment_foreground_colour = is_dark_mode ? Constants.Colours.SILVER_300 : Constants.Colours.BLACK_300;
            var app_background_colour = is_dark_mode ? Constants.Colours.BLACK_500: Constants.Colours.SILVER_300;

            var keyboard_shortcut_tip_foreground_colour = is_dark_mode ? Constants.Colours.SILVER_300 : Constants.Colours.BLACK_700;
            var keyboard_shortcut_tip_background_colour = is_dark_mode ? Constants.Colours.SLATE_500 : Constants.Colours.SLATE_100;

            var base_styles = @"
                /* Message scrolled window and text view */
                scrolledwindow {
                    background-color: $(message_background_colour);
                    border-radius: 0;
                }

                textview text {
                    background-color: $(message_background_colour);
                    color: $(message_foreground_colour);
                }

                textview {
                    font-size: 1.25em;
                }

                /* Background of window. */
                grid {
                    background-color: $(app_background_colour);
                }
            ";

            var comment_view_styles = @"
                textview {
                    background-color: $(app_background_colour);
                }

                textview text {
                    color: $(comment_foreground_colour);
                }
            ";

            var keyboard_shortcut_tip_styles = @"
                infobar.info {
                    color: $(keyboard_shortcut_tip_foreground_colour);
                }

                infobar.info > revealer > box {
                    background-color: $(keyboard_shortcut_tip_background_colour);
                }
            ";

            // Create the CSS providers if necessary and remove existing ones
            // from the components otherwise.
            if (base_styles_css_provider == null) {
                base_styles_css_provider = new Gtk.CssProvider ();
                comment_view_css_provider = new Gtk.CssProvider ();

                if (keyboard_shortcut_tip != null) {
                    keyboard_shortcut_tip_css_provider = new Gtk.CssProvider ();
                }

            } else {
                grid.get_style_context ().remove_provider (base_styles_css_provider);
                message_scrolled_window.get_style_context ().remove_provider (base_styles_css_provider);
                message_view.get_style_context ().remove_provider (base_styles_css_provider);
                comment_view.get_style_context ().remove_provider (comment_view_css_provider);
                button_box.get_style_context ().remove_provider (base_styles_css_provider);

                if (keyboard_shortcut_tip != null) {
                    keyboard_shortcut_tip.get_style_context ().remove_provider (keyboard_shortcut_tip_css_provider);
                }
            }

            // Load the new styles.
            base_styles_css_provider.load_from_data (base_styles, -1);
            comment_view_css_provider.load_from_data (comment_view_styles, -1);

            // Add the CSS providers.
            grid.get_style_context ().add_provider (base_styles_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            message_scrolled_window.get_style_context ().add_provider (base_styles_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            message_view.get_style_context ().add_provider (base_styles_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            comment_view.get_style_context ().add_provider (comment_view_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            button_box.get_style_context ().add_provider (base_styles_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            if (keyboard_shortcut_tip != null) {
                keyboard_shortcut_tip_css_provider.load_from_data (keyboard_shortcut_tip_styles, -1);
                // Note: we add the CSS Provider to the screen as it’s only way to get it
                // ===== to work. The following, commented-out method of adding it to the Gtk.InfoBar itself
                //       does *not* work. See https://elementarycommunity.slack.com/archives/C013GMHPS80/p1636718109000400
                //  keyboard_shortcut_tip.get_style_context ().add_provider (keyboard_shortcut_tip_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), keyboard_shortcut_tip_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            }

            // Update the colour of the spelling mistake indicator underline.
            var strawberry = Gdk.RGBA ();
            strawberry.parse (is_dark_mode ? Constants.Colours.STRAWBERRY_300 : Constants.Colours.STRAWBERRY_700);
            underline_colour_tag.underline_rgba = strawberry;
        }

        private void hide_keyboard_shortcut_tip () {
            if (keyboard_shortcut_tip != null) {
                // Make sure we don’t show it again.
                Comet.saved_state.set_boolean (Constants.Names.Settings.SHOW_KEYBOARD_SHORTCUT_TIP, false);

                // Make the tip disappear and resize the window to remove the space
                // that was used up by it. This is more abrupt than I’d like it but
                // I’m not sure how to animate it any more smoothly at this time.
                // If anyone else does, pull requests are welcome ;)
                keyboard_shortcut_tip.visible = false;

                // Note: this will resize the window to the minimum size it can
                // given all the various restraints. It won’t resize it to 1px by 1px :)
                this.resize (1, 1);
            }
        }


        private void action_commit () {
            hide_keyboard_shortcut_tip ();
            if (validate_commit_button ()) {
                save_commit_message_and_exit ();
            }
        }


        private void save_commit_message_and_exit () {
            try {
                app.model.save ();
                quit_on_future_stack_frame ();
            } catch (FileError error) {
                // TODO: Handle this better.
                warning (_("Could not save commit message."));
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
            // Always highlight with bright banana yellow on dark text,
            // regardless of the colour scheme.
            highlight_background_tag.background = Constants.Colours.BANANA_500;
            highlight_background_tag.foreground = is_dark_mode ? message_background_colour : message_foreground_colour;
        }


        private void update_first_line_character_limit () {
            first_line_character_limit = Comet.saved_state.get_int (Constants.Names.Settings.FIRST_LINE_CHARACTER_LIMIT);
            highlight_text ();
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
            var characters_left = first_line_character_limit - first_line_length;
            if ((characters_left < 15) && (characters_left > -1) && cursor_position_iter.compare(glyph_count_iter) <= 0) {
                if (overlay_bar == null) {
                    // Create overlay bar to display hint about number of characters left.
                    // Note: the overlay bar does not appear to adapt its look depending on
                    // colour scheme and I can’t seem to find a way to do it via CSS.
                    // I’ve asked on Granite discussions. If there isn’t an easy way, it
                    // would be easier just to recreate a simple version of it myself.
                    // (https://github.com/elementary/granite/discussions/537)
                    overlay_bar = new Granite.Widgets.OverlayBar (overlay);
                    overlay.show_all ();
                }

                string status_message;
                if (characters_left == 0) {
                    status_message = _("No characters left on first line.");
                } else {
                    // To understand why we’re doing it this way for localisation,
                    // please read https://wiki.gnome.org/TranslationProject/DevGuidelines/Plurals
                    status_message = ngettext ("%d character left on first line.", "%d characters left on first line.", (ulong) characters_left).printf (characters_left);
                }
                overlay_bar.label = status_message;
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
            if (first_line_length > first_line_character_limit) {
                Gtk.TextIter start_of_overflow_iterator;
                message_view_buffer.get_start_iter (out start_of_overflow_iterator);
                start_of_overflow_iterator.forward_cursor_positions (first_line_character_limit);
                message_view_buffer.apply_tag (highlight_background_tag, start_of_overflow_iterator, end_of_first_line_iterator);
            }
        }
    }
}
