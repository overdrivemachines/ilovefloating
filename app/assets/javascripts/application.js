// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require activestorage
//= require turbolinks
//= require_tree .

$(document).on("turbolinks:load", function() {
  // Item radio button
  $(".form-check:first").addClass("is-selected");
  $(".form-check:first").children("input[name='transaction[item]']:radio")
      .eq(0)
      .prop("checked", true);
  $(".form-check").click(function() {
    $(this).addClass("is-selected");
    $(this)
      .siblings()
      .removeClass("is-selected");
    $(this)
      .children("input[name='transaction[item]']:radio")
      .eq(0)
      .prop("checked", true);
  });

  // Create a Stripe client.
  // var stripe = Stripe("pk_test_gEtbe0LdmNqijbYBOZUMe9kx");
  var stripe = Stripe("pk_live_ggQscJWE7yBEpXZDGMIVO2ku");

  // Create an instance of Elements.
  var elements = stripe.elements();

  var style = {
    base: {
      iconColor: "#c4f0ff",
      color: "#fff",
      fontWeight: 500,
      fontFamily: "Roboto, Open Sans, Segoe UI, sans-serif",
      fontSize: "16px",
      fontSmoothing: "antialiased",
      ":-webkit-autofill": {
        color: "#fce883"
      },
      "::placeholder": {
        color: "#87BBFD"
      }
    },
    invalid: {
      iconColor: "#FFC7EE",
      color: "#FFC7EE"
    }
  };

  // Create an instance of the card Element.
  var card = elements.create("card", { style: style });

  // Add an instance of the card Element into the `card-element` <div>.
  card.mount("#card-element");

  // Handle form submission.
  var form = document.getElementById('new-transaction-form');
  form.addEventListener('submit', function(event) {
    event.preventDefault();


    stripe.createToken(card).then(function(result) {
      if (result.error) {
        // Inform the user if there was an error.
        var errorElement = document.getElementById('card-errors');
        errorElement.textContent = result.error.message;
        enableSubmitButton();
      } else {
        // Send the token to your server.
        stripeTokenHandler(result.token);
      }
    });
  });

  function enableSubmitButton() {
    $("#new-transaction-form input[type='submit']").attr('disabled', false);
    $("#new-transaction-form input[type='submit']").prop('disabled', false);
  }

  // Submit the form with the token ID.
  function stripeTokenHandler(token) {
    // Insert the token ID into the form so it gets submitted to the server
    var form = document.getElementById('new-transaction-form');
    var hiddenInput = document.createElement('input');
    hiddenInput.setAttribute('type', 'hidden');
    hiddenInput.setAttribute('name', 'stripeToken');
    hiddenInput.setAttribute('value', token.id);
    form.appendChild(hiddenInput);

    // Submit the form
    form.submit();
  }
});