namespace Comet {

    public class Model : Object {

        public string original_text { get; private set; }

        public string message { get; private set; }
        public Gtk.TextBuffer message_buffer { get; private set; }

        public string comment { get; private set; }
        public Gtk.TextBuffer comment_buffer { get; private set; }

        public string action { get; private set; }
        public string detail { get; private set; }

        private string commit_message_file_path;

        public bool initialise_with_commit_message_file (File commit_message_file) throws FileError {
            commit_message_file_path = commit_message_file.get_path ();

            //
            // Ascertain type of git message from its file path.
            //

            // Generic commit message.
            var is_git_commit_message = commit_message_file_path.index_of ("COMMIT_EDITMSG") > -1;
            var is_test_commit_message = commit_message_file_path.index_of ("tests/message-with-body") > -1
                || commit_message_file_path.index_of ("tests/message-without-body") > -1;
            var is_commit_message = is_git_commit_message || is_test_commit_message;

            // Git merge message.
            var is_git_merge_message = commit_message_file_path.index_of ("MERGE_MSG") > -1;
            var is_test_merge_message = commit_message_file_path.index_of ("tests/merge") > -1;
            var is_merge_message = is_git_merge_message || is_test_merge_message;

            // Git tag message.
            var is_git_tag_message  = commit_message_file_path.index_of ("TAG_EDITMSG") > -1;
            var is_test_tag_message = commit_message_file_path.index_of ("tests/tag-message") > -1;
            var is_tag_message = is_git_tag_message || is_test_tag_message;

            // AddP Hunk Edit message.
            var is_git_add_p_hunk_edit_message = commit_message_file_path.index_of ("addp-hunk-edit.diff") > -1;
            var is_test_add_p_hunk_edit_message = commit_message_file_path.index_of ("tests/add-p-edit-hunk") > -1;
            var is_add_p_hunk_edit_message = is_git_add_p_hunk_edit_message || is_test_add_p_hunk_edit_message;

            // Rebase message.
            var is_git_rebase_message = commit_message_file_path.index_of ("rebase-merge/git-rebase-todo") > -1;
            var is_test_rebase_message = commit_message_file_path.index_of ("tests/rebase") > -1;
            var is_rebase_message = is_git_rebase_message || is_test_rebase_message;

            var is_test = is_test_commit_message || is_test_tag_message || is_test_add_p_hunk_edit_message || is_test_rebase_message || is_test_merge_message;

            string commit_message_file_contents;
            size_t commit_message_file_length;

            FileUtils.get_contents (commit_message_file_path, out commit_message_file_contents, out commit_message_file_length);

            original_text = commit_message_file_contents;

            var text = original_text;

            // Escape tag start/end as we will be using markup to populate the buffer.
            // (Otherwise, rebase -i commit messages fail, as they contain the strings
            // <commit>, <label>, etc.
            try {
                var all_left_angular_brackets = new Regex (Regex.escape_string ("<"));
                var all_right_angular_brackets = new Regex ( Regex.escape_string (">"));
                text = all_left_angular_brackets.replace_literal (text, -1, 0, "&lt;");
                text = all_right_angular_brackets.replace_literal (text, -1, 0, "&gt;");
            } catch (RegexError e) {
                assert_not_reached ();
            }

            // If this is a git add -p hunk edit message, then we cannot
            // split at the first comment as the message starts with a comment.
            // Remove that comment and instead display that info in the instructions.
            if (is_add_p_hunk_edit_message) {
                text = text.substring (text.index_of ("\n")+1);
            }

            var first_comment_index = text.index_of ("#");

            // In case there is no comment for some reason, let’s not go further as this is likely not
            // a proper git commit message.
            if (first_comment_index == -1) {
                throw new FileError.INVAL (_("Comet: Sorry, this does not look like a valid git commit message (it’s missing a comment section):\n\n%s").printf(text));
            }

            message = text.slice (0, first_comment_index - 1);

            // Trim any newlines there may be at the end of the commit body
            while (message.length > 0 && message[message.length -1] == '\n') {
                message = message.slice (0, message.length - 1);
            }

            comment = text.slice (first_comment_index - 1, -1);

            // Remove the comment tokens.
            try {
                var all_comment_tokens = new Regex ("^#", RegexCompileFlags.MULTILINE);
                var all_lines_that_begin_with_a_space = new Regex ("^ ", RegexCompileFlags.MULTILINE);
                comment = all_comment_tokens.replace_literal (comment, -1, 0, "");
                comment = all_lines_that_begin_with_a_space.replace_literal (comment, -1, 0, "");
            } catch (RegexError e) {
                assert_not_reached ();
            }

            // Remove leading and trailing whitespace.
            var comment = comment.strip ();

            // Split the comment
            var comment_lines = new Gee.ArrayList<string>.wrap (comment.split ("\n"));
            //  var number_of_lines_in_comment = comment_lines.size;

            // The commit message is always in the .git directory in the
            // project directory. Get the project directory’s name by using this.
            string project_directory_name;
            if (is_test) {
                project_directory_name = "test";
            } else {
                var path_components = new Gee.ArrayList<string>.wrap (commit_message_file_path.split ("/"));
                var project_directory_name_index = path_components.index_of (".git");
                if (project_directory_name_index > 0) {
                    project_directory_name = path_components[project_directory_name_index - 1];
                } else {
                    // Comet was launche with a reference to a file that’s not in a .git
                    // folder or our test folder. This shouldn’t happen but it’s not really an
                    // error so we’ll allow it with a warning.
                    warning (@"$(commit_message_file_path) is not a git commit message.");
                    project_directory_name = commit_message_file_path;
                }
            }

            // The action and detail strings explain the type of commit action
            // that is about to be performed.

            action = "n/a";
            detail = "n/a";
            if (is_commit_message) {
                // Try to get the branch name via a method that relies on
                // positional aspect of the branch name so it should work with
                // other languages.
                var words_on_branch_line = comment_lines[3].split (" ");
                var branch_name = words_on_branch_line[words_on_branch_line.length - 1];
                action = "commit";
                detail = branch_name;
            } else if (is_merge_message) {
                // Display the branch name
                action = "merge";
                detail = @"branch $(comment.split ("'")[1])";
            } else if (is_tag_message) {
                // Get the version number from the message
                var version = comment_lines[2].slice (1, -1).strip ();
                action = "tag";
                detail = version;
            } else if (is_add_p_hunk_edit_message) {
                // git add -p: edit hunk message
                action = "add -p";
                detail = "manual hunk edit mode";
                // Remove the first line, which is ---
                comment_lines.remove_at (0);
                comment = string.joinv("\n", comment_lines.to_array ());
            } else if (is_rebase_message) {
                action = "rebase";
                var _detail = comment_lines[0].replace ("# ", "");
                var _detailChunks = _detail.split (" ");
                detail = @"$(_detailChunks[1]) → $(_detailChunks[3])";
            } else {
                // This should not happen.
                // TODO: Ensure this results in the ability to easily report this issue, like
                // we do with the errors (but without throwing an error as we don’t want to
                // stop the person from commiting just because we can’t format and display the
                // commit message in a nice way).
                warning (_("Warning: unknown Git commit type encountered in %s"), commit_message_file_path);
            }

            print (@"\nAction: $(action)");
            print (@"\nDetail: $(detail)");

            // Add Pango markup to make the commented area appear lighter.
            // TODO: Rewrite to make this work with adequate contrast under both light
            // and dark schemes.
            comment = @"<span foreground=\"#959595\">$(comment)</span>";

            // Populate the initial buffers.
            comment_buffer = new Gtk.TextBuffer (null);

            // Unfortunately, there’s no set_markup method like there is for
            // set_text so we have to use an iterator and the insert method.
            Gtk.TextIter comment_buffer_start_iterator;
            comment_buffer.get_start_iter (out comment_buffer_start_iterator);
            comment_buffer.insert_markup (ref comment_buffer_start_iterator, comment, -1);
            message_buffer = new Gtk.TextBuffer (null);
            message_buffer.set_text (message);

            // original_text.strip ().replace ("# ", "").replace("#\n", "\n").replace("#	", "  - ");
            return true;
        }


        public void save () throws FileError {
            FileUtils.set_contents (
                commit_message_file_path,
                message_buffer.text
            );
        }
    }
}
