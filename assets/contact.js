/* Contact form handler.
   Primary path: POST the fields to a form backend (Formspree) so submissions
   land reliably in the inbox. Until an endpoint is configured, it falls back to
   opening a pre-filled email to catarinamesquitafidalgo@gmail.com.

   TO ACTIVATE RELIABLE SUBMISSIONS:
   1. Create a free form at https://formspree.io (use catarinamesquitafidalgo@gmail.com).
   2. Copy your form endpoint (looks like https://formspree.io/f/abcdwxyz).
   3. Paste it into FORM_ENDPOINT below, replacing YOUR_FORM_ID.
*/
(function () {
  "use strict";

  var FORM_ENDPOINT = "https://formspree.io/f/YOUR_FORM_ID";
  var EMAIL = "catarinamesquitafidalgo@gmail.com";

  var form = document.getElementById("contact-form");
  if (!form) return;
  var status = document.getElementById("form-status");

  var val = function (id) {
    var el = document.getElementById(id);
    return el ? el.value.trim() : "";
  };

  function fields() {
    return {
      name: val("name"),
      email: val("email"),
      company: val("company"),
      video_type: val("video-type"),
      message: val("message")
    };
  }

  function mailtoFallback(f) {
    var subject = "Website inquiry — " + (f.name || "New message");
    var body =
      "Name: " + f.name + "\n" +
      "Email: " + f.email + "\n" +
      "Company: " + (f.company || "—") + "\n" +
      "Type of video: " + (f.video_type || "—") + "\n\n" +
      "Message:\n" + f.message + "\n";
    window.location.href = "mailto:" + EMAIL +
      "?subject=" + encodeURIComponent(subject) +
      "&body=" + encodeURIComponent(body);
    if (status) status.textContent = "Opening your email app… if nothing happens, email me directly at " + EMAIL + ".";
  }

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    if (typeof form.reportValidity === "function" && !form.reportValidity()) return;

    var f = fields();

    // Not yet configured → keep the site working via a pre-filled email.
    if (FORM_ENDPOINT.indexOf("YOUR_FORM_ID") !== -1 || !window.fetch) {
      mailtoFallback(f);
      return;
    }

    if (status) status.textContent = "Sending…";
    var btn = form.querySelector("button[type=submit]");
    if (btn) btn.disabled = true;

    fetch(FORM_ENDPOINT, {
      method: "POST",
      headers: { "Accept": "application/json", "Content-Type": "application/json" },
      body: JSON.stringify({
        name: f.name,
        email: f.email,
        company: f.company,
        video_type: f.video_type,
        message: f.message,
        _subject: "Website inquiry — " + (f.name || "New message")
      })
    })
      .then(function (res) {
        if (res.ok) {
          form.reset();
          if (status) status.textContent = "Thank you — your message is on its way. I'll get back to you personally.";
        } else {
          if (status) status.textContent = "Something went wrong. Please email me directly at " + EMAIL + ".";
        }
      })
      .catch(function () {
        if (status) status.textContent = "Couldn't send just now. Please email me directly at " + EMAIL + ".";
      })
      .finally(function () {
        if (btn) btn.disabled = false;
      });
  });
})();
