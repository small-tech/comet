namespace Comet {
    public class WelcomeWindow : Hdy.ApplicationWindow {

        public weak Comet.Application app { get; construct; }
        public Comet.Widgets.HeaderBar toolbar;

        public WelcomeWindow (Comet.Application application) {
            Object (
                // We must set the inherited application property for Hdy.ApplicationWindow
                // to initialise properly. However, this is not a set-type property (get; set;)
                // so the assignment is made after construction, which means that we cannot
                // reference the application during the construct method. This is why we also
                // declare a property called app that is construct-type (get; construct;) which
                // is assigned before the constructors are run.
                //
                // So use the app property when referencing the application instance from
                // the constructors. Anywhere else, they can be used interchangably.
                app: application,
                application: application,                    // DON’T use in constructors; won’t have been assigned yet.
                hide_titlebar_when_maximized: true,          // FIXME: This does not seem to have an effect. Why not?
                icon_name: "com.github.small_tech.comet"
            );
        }

        // This constructor is guaranteed to be run only once during the lifetime of the application.
        static construct {
            // Initialise the Handy library.
            // https://gnome.pages.gitlab.gnome.org/libhandy/
            // (Apps in elementary OS 6 use the Handy library extensions
            // instead of GTKApplicationWindow, etc., directly.)
            Hdy.init();
        }

        construct {
            // Set color scheme of app based on person’s preference.
            var granite_settings = Granite.Settings.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();
            gtk_settings.gtk_application_prefer_dark_theme
                = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

            // Listen for changes in person’s color scheme settings
            // and update color scheme of app accordingly.
            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme
                    = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            });

            // Unlike GTK, in Handy, the header bar is added to the window’s content area.
            // See https://gnome.pages.gitlab.gnome.org/libhandy/doc/1-latest/HdyHeaderBar.html
            toolbar = new Comet.Widgets.HeaderBar ();
            toolbar.title = "";
            var grid = new Gtk.Grid ();
            grid.attach (toolbar, 0, 0);

            var welcome = new Granite.Widgets.Welcome ("Comet", "A beautiful git commit message editor.");
            welcome.append ("comet-128", "Enable Comet", "Use Comet as the default editor for commit messages.");
            welcome.append ("help-faq", "Help", "Having trouble? Get help and report issues.");

            welcome.set_size_request (560, 320);

            grid.attach (welcome, 0, 1);

            add (grid);

            show_all ();

            welcome.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        try {
                            var result = Posix.system ("flatpak-spawn --host git config --global core.editor \"flatpak run com.github.small_tech.Comet\"");
                            if (result == 0) {
                                print("Git configured :)");
                            } else {
                                print("Git configuration failed.");
                            }
                        } catch (Error e) {
                            warning (e.message);
                        }
                    break;

                    case 1:
                        try {
                            AppInfo.launch_default_for_uri ("https://github.com/small-tech/comet#readme", null);
                        } catch (Error e) {
                            warning (e.message);
                        }
                    break;
                }
            });
        }
    }
}
