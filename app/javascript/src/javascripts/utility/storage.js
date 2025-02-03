import StorageUtils from "./storage_util";

const LStorage = {};

// Backwards compatibility
LStorage.get = function (name) {
  return localStorage[name];
};
LStorage.getObject = function (name) {
  const value = this.get(name);
  if (!value) return null;

  try {
    return JSON.parse(value);
  } catch (error) {
    console.log(error);
    return null;
  }
};

LStorage.put = function (name, value) {
  localStorage[name] = value;
};
LStorage.putObject = function (name, value) {
  this.put(name, JSON.stringify(value));
};

LStorage.isAvailable = function () {
  try {
    localStorage.setItem("test", "a");
    localStorage.removeItem("test");
  } catch {
    return false;
  }
  return true;
};

// Content that does not belong anywhere else
LStorage.Site = {
  /** @returns {number} Currently displayed Mascot ID, or 0 if none is selected */
  Mascot: ["mascot", 0],

  /** @returns {number} Last news update ID, or 0 if none is selected */
  NewsID: ["hide_news_notice", 0],
};
StorageUtils.bootstrapMany(LStorage.Site);


// Site themes and other visual options
// Note that these are HARD-CODED in theme_include.html.erb
// Any changes here must be reflected there as well
LStorage.Theme = {
  /** @returns {string} Main theme */
  Main: ["theme", "hexagon"],

  /** @returns {string} Extra theme / seasonal decotrations */
  Extra: ["theme-extra", "hexagon"],

  /** @returns {string} Colorblind-friendly palette (default / deut / trit) */
  Palette: ["theme-palette", "default"],

  /** @returns {string} Position of the navbar on the post page (top / bottom / both / none) */
  Navbar: ["theme-nav", "top"],

  /** @returns {boolean} True if the mobile gestures should be enabled */
  Gestures: ["emg", false],
};
StorageUtils.bootstrapMany(LStorage.Theme);


// Values relevant to the posts pages
LStorage.Posts = {
  /** @returns {string} Viewing mode on the search page */
  Mode: ["mode", "view"],

  /** @returns {boolean} True if parent/child posts preview should be visible */
  ShowPostChildren: ["show-relationship-previews", false],

  /** @returns {boolean} True if the janitor toolbar should be visible */
  JanitorToolbar: ["jtb", true],
};
StorageUtils.bootstrapMany(LStorage.Posts);

LStorage.Posts.TagScript = {
  /** @returns {number} Current tag script ID */
  get ID() {
    if (!this._tagScriptID)
      this._tagScriptID = Number(localStorage.getItem("current_tag_script_id") || "1");
    return this._tagScriptID;
  },
  set ID(value) {
    this._tagScriptID = value;
    if (value == 1) localStorage.removeItem("current_tag_script_id");
    else localStorage.setItem("current_tag_script_id", value);
  },
  _tagScriptID: undefined,

  /** @returns {string} Current tag script contents */
  get Content() {
    return localStorage.getItem("tag-script-" + this.ID) || "";
  },
  set Content(value) {
    if (value == "") localStorage.removeItem("tag-script-" + this.ID);
    else localStorage.setItem("tag-script-" + this.ID, value);
  },
};

export default LStorage;
