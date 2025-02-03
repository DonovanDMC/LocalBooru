const Thumbnails = {};

Thumbnails.initialize = function () {
  const postsData = window.___deferred_posts || {};
  const posts = $(".post-thumb.placeholder, .thumb-placeholder-link");
  const replacedPosts = [];

  for (const post of posts) {
    const $post = $(post);

    // Placeholder is valid
    const postID = $post.data("id");
    if (!postID) {
      clearPlaceholder($post);
      continue;
    }

    // Data exists for this post
    const postData = postsData[postID];
    if (!postData) {
      clearPlaceholder($post);
      continue;
    }

    // Building the element
    const thumbnail = $("<div>")
      .addClass("post-thumbnail")
      .toggleClass("dtext", $post.hasClass("thumb-placeholder-link"));

    for (const key in postData)
      thumbnail.attr("data-" + key.replace(/_/g, "-"), postData[key]);

    const link = $("<a>")
      .attr("href", `/posts/${postData.id}`)
      .appendTo(thumbnail);

    $("<img>")
      .attr({
        src: postData["preview_url"] || "/images/deleted-preview.png",
        height: postData["preview_url"] ? postData["preview_height"] : 150,
        width: postData["preview_url"] ? postData["preview_width"] : 150,
        title: `Rating: ${postData.rating}\r\nID: ${postData.id}\r\nStatus: ${postData.flags}\r\nDate: ${postData["created_at"]}\r\n\r\n${postData.tags}`,
        alt: postData.tags,
        class: "post-thumbnail-img",
      })
      .appendTo(link);

    $post.replaceWith(thumbnail);
    replacedPosts.push(thumbnail);
  }

  function clearPlaceholder(post) {
    if (post.hasClass("thumb-placeholder-link"))
      post.removeClass("thumb-placeholder-link");
    else post.empty();
  }
};

$(() => {
  Thumbnails.initialize();
  $(window).on("e621:add_deferred_posts", (_, posts) => {
    window.___deferred_posts = window.___deferred_posts || {};
    window.___deferred_posts = $.extend(window.___deferred_posts, posts);
    Thumbnails.initialize();
  });
  $(document).on("thumbnails:apply", Thumbnails.initialize);
});

export default Thumbnails;
