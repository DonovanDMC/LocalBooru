import Utility from "./utility";

let PostReplacement = {};

PostReplacement.initialize_all = function () {
  $(".replacement-approve-action").on("click", e => {
    const target = $(e.target);
    e.preventDefault();
    PostReplacement.approve(target.data("replacement-id"));
  });
  $(".replacement-reject-action").on("click", e => {
    e.preventDefault();
    PostReplacement.reject($(e.target).data("replacement-id"));
  });
  $(".replacement-promote-action").on("click", e => {
    e.preventDefault();
    PostReplacement.promote($(e.target).data("replacement-id"));
  });
};

PostReplacement.approve = function (id) {
  const $row = $("#replacement-" + id);
  make_processing($row);
  $.ajax({
    type: "PUT",
    url: `/posts/replacements/${id}/approve.json`,
    dataType: "json",
  }).done(function () {
    set_status($row, "approved");
  }).fail(function (data) {
    Utility.error(data.responseText);
    set_status($row, "replacement failed");
  });
};

PostReplacement.reject = function (id) {
  if (!confirm("Are you sure you want to reject this replacement?"))
    return;
  const $row = $("#replacement-" + id);
  make_processing($row);
  $.ajax({
    type: "PUT",
    url: `/posts/replacements/${id}/reject.json`,
    dataType: "json",
  }).done(function () {
    set_status($row, "rejected");
  }).fail(function (data) {
    Utility.error(data.responseText);
    set_status($row, "rejecting failed");
  });
};

PostReplacement.promote = function (id) {
  if (!confirm("Are you sure you want to promote this replacement?"))
    return;
  const $row = $("#replacement-" + id);
  make_processing($row);
  $.ajax({
    type: "POST",
    url: `/posts/replacements/${id}/promote.json`,
    dataType: "json",
  }).done(function (data) {
    Utility.notice(`Replacement promoted to post #${data.post.id}`);
    set_status($row, "promoted");
  }).fail(function (data) {
    Utility.error(data.responseText);
    set_status($row, "promoting failed");
  });
};

function make_processing($row) {
  $row.removeClass("replacement-pending-row").addClass("replacement-processing-row");
  $row.find(".replacement-status").text("processing");
  $row.find(".pending-links a").addClass("disabled-link");
}

function set_status($row, text) {
  $row.find(".replacement-status").text(text);
  $row.removeClass("replacement-processing-row");
}

$(function () {
  if ($("#c-posts-replacements").length)
    PostReplacement.initialize_all();
});


export default PostReplacement;
