// The strings in here need to be translated not for use in the app itself
// but in the screenshots used in AppCenter.
//
// Note that the Git comments shown in the screenshots don’t need to be
// translated as they are already localised by git itself.
//
// You do not have to take the screenshots yourself, Aral will do that
// on his machine for consistency.
//
// For more information, please see the AppCenter screenshots section of the
// Translations part of the readme.

namespace Constants.AppCenterCopy {
    // Screenshot showing the main editor in both light and dark
    // styles. In the English version, the text “too long” goes over the
    // 72 character limit and is highlighted. It would be nice to try and
    // keep the same feel in translations if possible.
    public const string DEMONSTRATION_OF_LINE_LIMIT = _("This is the summary line of your Git commit message; make sure it isn’t too long\n\nYou can change the suggested length in the Settings Menu.");

    // Screenshot showing the Settings Menu with the first line character
    // limit set to 50 (Dogmatic). In the editor view you can see the message,
    // partially obscured by the Settings Menu, giving a dictionary-like
    // definition of dogma (n = short for noun in English).
    public const string DEFINITION_OF_DOGMA = _("Dogma (n): a settled opinion, belief, or principle ");

    // Screenshot showing the emoji picker. The message here is shown in the editor.
    // Please feel free to use Ctrl as a generic label for Control for translations
    // unless there is a different ubiquitously used acronym for the Control key in
    // your language. (In Turkish texts, for example, the key is almost universally
    // refered to as Ctrl).
    public const string EMOJI_PICKER_INSTRUCTIONS = _("Press Control + . (period) to insert emoji");
}
