import Utility from "./utility";

class PostDeletionReasons {
  static init(spacing) {
    const $addSpacingBelowLink = $(".add-spacing-below-link");
    const $addSpacingAboveLink = $(".add-spacing-above-link");
    const $editOrderLink = $(".edit-order-link");
    const $saveOrderLink = $(".save-order-link");
    const $addSpacingLink = $(".add-spacing-link");
    const $removeSpacingLink = $(".remove-spacing-link");
    const $sortablePostDeletionReasons = $("#post-deletion-reasons-table tbody");
    $addSpacingBelowLink.on("click.femboyfans.spacing", function(event) {
      event.preventDefault();
      spacing.insertAfter($(this).closest("tr"));
      PostDeletionReasons.reinitRemoveListener();
    });

    $addSpacingAboveLink.on("click.femboyfans.spacing", function(event) {
      event.preventDefault();
      spacing.insertBefore($(this).closest("tr"));
      PostDeletionReasons.reinitRemoveListener();
    });

    $editOrderLink.on("click.femboyfans.sorting", function(event) {
      event.preventDefault();
      $saveOrderLink.show();
      $editOrderLink.hide();
      $addSpacingLink.show();
      $removeSpacingLink.show();
      $sortablePostDeletionReasons.sortable();
      Utility.notice("Drag and drop to reorder.");
    });

    $saveOrderLink.on("click.femboyfans.sorting", function(event) {
      event.preventDefault();
      $saveOrderLink.hide();
      $addSpacingLink.hide();
      $removeSpacingLink.hide();
      $sortablePostDeletionReasons.sortable("disable");
      $.ajax({
        url: "/posts/deletion_reasons/reorder.json",
        type: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        data: PostDeletionReasons.reorderData(),
        success() {
          Utility.notice("Order updated.");
          $editOrderLink.show();
        },
        error() {
          Utility.error("Failed to update order.");
          $saveOrderLink.show();
          $sortablePostDeletionReasons.sortable();
        }
      });
    });
    this.reinitRemoveListener();
  }

  static reinitRemoveListener() {
    const $removeSpacingLink = $(".remove-spacing-link");
    $removeSpacingLink.off("click.femboyfans.spacing");
    $removeSpacingLink.on("click.femboyfans.spacing", function(event) {
      event.preventDefault();
      $(this).closest("tr").remove();
    });
  }

  static reorderData() {
    return JSON.stringify(Array.from($("#post-deletion-reasons-table tr")).slice(1).map((element, index) => ({ id: element.dataset.id ? Number(element.dataset.id) : null, order: index + 1 })));
  }
}

export default PostDeletionReasons;
