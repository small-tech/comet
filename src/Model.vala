namespace Comet {
    public class Model : Object {

        public string original_text { get; private set; }

        public string message { get; private set; }
        public Gtk.TextBuffer message_buffer { get; private set; }

        public string comment { get; private set; }
        public Gtk.TextBuffer comment_buffer { get; private set; }

        private string commit_message_file_path;

        public Model (File commit_message_file) {

            commit_message_file_path = commit_message_file.get_path ();

            string commit_message_file_contents;
            size_t commit_message_file_length;

            try {
                FileUtils.get_contents (commit_message_file_path, out commit_message_file_contents, out commit_message_file_length);
            } catch (Error error) {
                warning (error.message);
            }

            print (@"File path: $(commit_message_file_path)\n");
            print (@"Contents: \n\n $(commit_message_file_contents)\n");

            original_text = commit_message_file_contents;

            // Parse the original message from git to populate the model.
            message = "";
            comment = original_text.strip ().replace ("# ", "").replace("#\n", "\n").replace("#	", "  - ");
        }
    }
}
