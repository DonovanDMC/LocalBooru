import Utility from "../utility";

export default class CurrentUser {
  static get name() {
    return document.body.dataset.userName;
  }

  static get ipAddr() {
    return document.body.dataset.userIpAddr;
  }

  static get perPage() {
    return Number(document.body.dataset.userPerPage);
  }

  static get isAnonymous() {
    return document.body.dataset.userIsAnonymous === "true";
  }

  static get isMember() {
    return document.body.dataset.userIsMember === "true";
  }

  static get isSystem() {
    return document.body.dataset.userIsSystem === "true";
  }

  static get enableJsNavigation() {
    return Utility.meta("enable-js-navigation") === "true";
  }

  static get enableAutocomplete() {
    return Utility.meta("enable-autocomplete") === "true";
  }

  static get styleUsernames() {
    return Utility.meta("style-usernames") === "true";
  }
}
