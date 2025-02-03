import Utility from "./utility";
import Post from "./posts";
import Favorite from "./favorites";
import TagScript from "./tag_script";
import Rails from "@rails/ujs";
import Shortcuts from "./shortcuts";
import LStorage from "./utility/storage";

let PostModeMenu = {};

PostModeMenu.initialize = function () {
  if ($("#c-posts").length || $("#c-favorites").length || $("#c-pools").length) {
    this.initialize_selector();
    this.initialize_preview_link();
    this.initialize_edit_form();
    this.initialize_tag_script_field();
    this.initialize_shortcuts();
    PostModeMenu.change();
  }
};

PostModeMenu.initialize_shortcuts = function () {
  Shortcuts.keydown("1 2 3 4 5 6 7 8 9 0", "change_tag_script", PostModeMenu.change_tag_script);
};

PostModeMenu.show_notice = function (i) {
  Utility.notice("Switched to tag script #" + i + ". To switch tag scripts, use the number keys.");
};

PostModeMenu.change_tag_script = function (e) {
  if ($("#mode-box-mode").val() !== "tag-script")
    return;
  e.preventDefault();

  const newScriptID = Number(e.key);
  console.log(newScriptID, LStorage.Posts.TagScript.ID);
  if (!newScriptID || newScriptID == LStorage.Posts.TagScript.ID)
    return;

  LStorage.Posts.TagScript.ID = newScriptID;
  console.log("settings", LStorage.Posts.TagScript.ID, LStorage.Posts.TagScript.Content);
  $("#tag-script-field").val(LStorage.Posts.TagScript.Content);
  PostModeMenu.show_notice(newScriptID);
};

PostModeMenu.initialize_selector = function () {
  $("#mode-box-mode").val(LStorage.Posts.Mode);

  $("#mode-box-mode").on("change.danbooru", function () {
    PostModeMenu.change();
    $("#tag-script-field:visible").focus().select();
  });
};

PostModeMenu.initialize_preview_link = function () {
  $(".post-preview").on("click.danbooru", PostModeMenu.click);
};

PostModeMenu.initialize_edit_form = function () {
  $("#quick-edit-div").hide();
  $("#quick-edit-form input[value=Cancel]").on("click.danbooru", function (e) {
    PostModeMenu.close_edit_form();
    e.preventDefault();
  });

  $("#quick-edit-form").on("submit.danbooru", function (e) {
    $.ajax({
      type: "put",
      url: $("#quick-edit-form").attr("action"),
      data: {
        post: {
          tag_string: $("#post_tag_string").val(),
        },
      },
      complete: function () {
        Rails.enableElement(document.getElementById("quick-edit-form"));
      },
      success: function (data) {
        Post.update_data(data);
        Utility.notice("Post #" + data.post.id + " updated");
        PostModeMenu.close_edit_form();
      },
    });

    e.preventDefault();
  });
};

PostModeMenu.close_edit_form = function () {
  Shortcuts.disabled = false;
  $("#quick-edit-div").slideUp("fast");
  if (Utility.meta("enable-autocomplete") === "true") {
    $("#post_tag_string").data("uiAutocomplete").close();
  }
};

PostModeMenu.initialize_tag_script_field = function () {
  $("#tag-script-field").on("blur", function () {
    const script = $(this).val();
    LStorage.Posts.TagScript.Content = script;
  });

  $("#tag-script-all").on("click", PostModeMenu.tag_script_apply_all);
};

PostModeMenu.tag_script_apply_all = function (event) {
  event.preventDefault();
  $("article.post-preview").trigger("click");
};

PostModeMenu.change = function () {
  $("#quick-edit-div").slideUp("fast");
  const s = $("#mode-box-mode").val();
  if (s === undefined) {
    return;
  }
  $("#page").attr("data-mode-menu", s);
  LStorage.Posts.Mode = s;
  $("#set-id").hide();
  $("#tag-script-ui").hide();
  $("#quick-mode-reason").hide();

  if (s === "tag-script") {
    $("#tag-script-ui").show();
    $("#tag-script-field").val(LStorage.Posts.TagScript.Content).show();
    PostModeMenu.show_notice(LStorage.Posts.TagScript.ID);
  } else if (s === "delete") {
    $("#quick-mode-reason").show();
  }
};

PostModeMenu.open_edit = function (post_id) {
  Shortcuts.disabled = true;
  var $post = $("#post_" + post_id);
  $("#quick-edit-div").slideDown("fast");
  $("#quick-edit-form").attr("action", "/posts/" + post_id + ".json");
  $("#post_tag_string").val($post.data("tags") + " ").focus().selectEnd();

  /* Set height of tag edit box to fit content. */
  $("#post_tag_string").height(80); // min height: 80px.
  var padding = $("#post_tag_string").innerHeight() - $("#post_tag_string").height();
  var height = $("#post_tag_string").prop("scrollHeight") - padding;
  $("#post_tag_string").height(height);
};

PostModeMenu.click = function (e) {
  const mode = $("#mode-box-mode").val();
  const post_id = $(e.currentTarget).data("id");

  switch (mode) {
    case "add-fav":
      Favorite.create(post_id);
      break;
    case "remove-fav":
      Favorite.destroy(post_id);
      break;
    case "edit":
      PostModeMenu.open_edit(post_id);
      break;
    case "rating-s":
      Post.update(post_id, {"post[rating]": "s"});
      break;
    case "rating-q":
      Post.update(post_id, {"post[rating]": "q"});
      break;
    case "rating-e":
      Post.update(post_id, {"post[rating]": "e"});
      break;
    case "delete":
      Post.delete_with_reason(post_id, $("#quick-mode-reason").val(), false);
      break;
    case "undelete":
      Post.undelete(post_id);
      break;
    case "remove-parent":
      Post.update(post_id, {"post[parent_id]": ""});
      break;
    case "tag-script": {
      const tag_script = LStorage.Posts.TagScript.Content;
      if (!tag_script) {
        e.preventDefault();
        return;
      }
      const postTags = $("#post_" + post_id).data("tags").split(" ");
      const tags = new Set(postTags);
      const changes = TagScript.run(tags, tag_script);
      Post.tagScript(post_id, changes);
      break;
    }
    default:
      return;
  }

  e.preventDefault();
};

$(function () {
  PostModeMenu.initialize();
});

export default PostModeMenu;
