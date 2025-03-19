import LStorage from "./utility/storage";

const Mascots = {
  current: 0,
};

function showMascot (mascot) {
  $("body").css("background-image", "url(" + mascot.background_url + ")");
  $("body").css("background-color", mascot.background_color);
  $(".mascotbox").css("background-image", "url(" + mascot.background_url + ")");
  $(".mascotbox").css("background-color", mascot.background_color);

  const creatorLink = $("<span>").text("Mascot by ").append($("<a>").text(mascot.creator_name).attr("href", mascot.creator_url));
  $("#mascot_creator").empty().append(creatorLink);
}

function changeMascot () {
  const mascots = window.mascots;

  const availableMascotIds = Object.keys(mascots);
  const currentMascotIndex = availableMascotIds.indexOf(Mascots.current + "");

  Mascots.current = availableMascotIds[(currentMascotIndex + 1) % availableMascotIds.length];
  showMascot(mascots[Mascots.current]);

  LStorage.Site.Mascot = Mascots.current;
}

function initMascots () {
  const changeMascotButton = $("#change-mascot");
  if (Object.keys(window.mascots).length === 0) {
    console.log("No mascots to display");
    changeMascotButton.remove();
    return;
  }

  changeMascotButton.on("click", changeMascot);
  const mascots = window.mascots;

  Mascots.current = LStorage.Site.Mascot;
  if (!mascots[Mascots.current]) {
    const availableMascotIds = Object.keys(mascots);
    const mascotIndex = Math.floor(Math.random() * availableMascotIds.length);
    Mascots.current = availableMascotIds[mascotIndex];
  }
  showMascot(mascots[Mascots.current]);
}

$(function () {
  if ($("#c-static > #a-home").length)
    initMascots();
});
