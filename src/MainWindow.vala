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
            model = new Comet.Model ();

            try {
                model.initialise_with_commit_message_file (app.commit_message_file);
                create_view ();
            } catch (FileError error) {
                create_error_view (error.message);
            }
        }

        private void create_view () {
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

            message_scrolled_window.add (message_view);

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

            show_all ();
        }

        private void create_error_view (string error_message) {

            var hBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var icon = new Gtk.Image.from_icon_name ("comet-128", Gtk.IconSize.DIALOG);
            var vBox = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

            hBox.add (icon);
            hBox.add (vBox);

            var label = new Gtk.Label.with_mnemonic ("Error: Could not read git commit message.");

            var details_view = new Gtk.TextView ();
            details_view.border_width = 6;
            details_view.editable = false;
            details_view.pixels_below_lines = 3;
            details_view.wrap_mode = Gtk.WrapMode.WORD;
            details_view.get_style_context ().add_class (Granite.STYLE_CLASS_TERMINAL);

            var scroll_box = new Gtk.ScrolledWindow (null, null);
            scroll_box.margin_top = 12;
            scroll_box.min_content_height = 70;
            scroll_box.add (details_view);

            var expander = new Gtk.Expander (_("Details"));
            expander.add (scroll_box);

            vBox.add (label);
            vBox.add (expander);

            // Add the action buttons.
            var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            //  button_box.margin = 12;
            button_box.layout_style = Gtk.ButtonBoxStyle.CENTER;
            var quit_button = new Gtk.Button.with_label (_("Quit"));
            button_box.add (quit_button);

            grid.attach(hBox, 0, 1);
            grid.attach(button_box, 0, 2);

            //  var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            //      "Basic information and a suggestion",
            //      "Further details, including information that explains any unobvious consequences of actions.",
            //      "phone",
            //      Gtk.ButtonsType.CANCEL
            //  );
            //  message_dialog.badge_icon = new ThemedIcon ("comet-128");
            //  //  message_dialog.set_transient_for (new Gtk.Window ());
            //  //  message_dialog.transient_for = this;

            //  var suggested_button = new Gtk.Button.with_label ("Suggested Action");
            //  suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            //  message_dialog.add_action_widget (suggested_button, Gtk.ResponseType.ACCEPT);

            //  var custom_widget = new Gtk.CheckButton.with_label ("Custom widget");

            //  message_dialog.show_error_details ("The details of a possible error.");
            //  message_dialog.custom_bin.add (custom_widget);

            //  //  message_dialog.show_all ();
            //  message_dialog.response.connect ((response_id) => {
            //     if (response_id == Gtk.ResponseType.ACCEPT) {
            //        // noop

            //     }
            //     this.destroy ();
            //  });
            //  grid.attach (message_dialog, 0, 1);
        }
    }
}
