document.addEventListener("DOMContentLoaded", function () {
  const root = document.documentElement;
  const themeToggle = document.getElementById("theme_toggle");
  const savedTheme = window.localStorage.getItem("konfound-theme") || "light";
  root.dataset.theme = savedTheme;
  if (themeToggle) themeToggle.checked = savedTheme === "dark";

  if (themeToggle) {
    themeToggle.addEventListener("change", function () {
      const theme = themeToggle.checked ? "dark" : "light";
      root.dataset.theme = theme;
      window.localStorage.setItem("konfound-theme", theme);
    });
  }

  document.querySelectorAll(".nav-item").forEach(function (button) {
    button.addEventListener("click", function () {
      document.querySelectorAll(".nav-item").forEach((item) => item.classList.remove("active"));
      document.querySelectorAll(".tab-page").forEach((page) => page.classList.remove("active"));
      button.classList.add("active");
      const page = document.getElementById(button.dataset.tab);
      if (page) page.classList.add("active");
    });
  });

  if (window.Shiny) {
    Shiny.addCustomMessageHandler("scrollTo", function (id) {
      const element = document.getElementById(id);
      if (element) element.scrollIntoView({ behavior: "smooth", block: "start" });
    });

    Shiny.addCustomMessageHandler("copyText", async function (text) {
      try {
        await navigator.clipboard.writeText(text);
      } catch (error) {
        const helper = document.createElement("textarea");
        helper.value = text;
        document.body.appendChild(helper);
        helper.select();
        document.execCommand("copy");
        helper.remove();
      }
    });
  }
});
