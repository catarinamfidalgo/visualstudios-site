/* Contact form -> mailto. No backend: encode the fields into a pre-filled
   email to hello@visualstudios.pro and hand off to the visitor's mail client. */
(function () {
  "use strict";
  var form = document.getElementById("contact-form");
  if (!form) return;

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    if (typeof form.reportValidity === "function" && !form.reportValidity()) return;

    var val = function (id) {
      var el = document.getElementById(id);
      return el ? el.value.trim() : "";
    };
    var name = val("name"),
        email = val("email"),
        company = val("company"),
        budget = val("budget"),
        message = val("message");

    var subject = "Website inquiry — " + (name || "New message");
    var body =
      "Name: " + name + "\n" +
      "Email: " + email + "\n" +
      "Company: " + (company || "—") + "\n" +
      "Budget: " + (budget || "—") + "\n\n" +
      "Message:\n" + message + "\n";

    var href = "mailto:hello@visualstudios.pro" +
      "?subject=" + encodeURIComponent(subject) +
      "&body=" + encodeURIComponent(body);

    window.location.href = href;

    var status = document.getElementById("form-status");
    if (status) status.textContent = "Opening your email app… if nothing happens, email us directly at hello@visualstudios.pro.";
  });
})();
