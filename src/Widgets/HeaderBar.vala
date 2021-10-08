namespace Comet.Widgets {
    public class HeaderBar : Hdy.HeaderBar {
        public HeaderBar () {
            Object (
                title: _("Comet"),
                has_subtitle: false,
                show_close_button: true,
                hexpand: true
            );
        }
    }
}
