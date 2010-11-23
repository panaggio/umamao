// Autocomplete boxes used throughout the website.
//
// There are currently two kinds of autocomplete boxes: an all-purpose
// search box, that allows the user to click on each suggested item and
// go to its page, and a topic selection box, used when classifying
// questions and bulk-following topics.
//
// There are three main classes: Item, ItemBox and AutocompleteBox.
// Item takes care of defining how each individual suggested entry is
// displayed and the action to be taken when it is clicked. ItemBox keeps
// track of the currently selected entry and moving between suggestions.
// AutocompleteBox handles keyboard input and contacts the server to
// refresh suggestions.
//
// TODO:
// - Use setInterval to refresh suggestions.
// - Move utility functions somewhere else.
// - Internationalize.
// - Highlight entries where they match the input.
// - Factor this into multiple files that are only loaded when needed.
// - Remove outer <div /> in ItemBox, use <ul /> only.
//

// Utility functions.
window.Utils = window.Utils || {};

// Escapes every character in a string that has a special meaning in a
// regular expression.
// TODO: actually test this.
Utils.escapeRegExp = function (string) {
  return string.replace(/[\{\}\(\)\[\]\.\+\*\?\$\^\\]/g, "\\$&");
};

// Data item in an item box.
function Item(data) {
  this.url = data.url;
  this.html = data.html;
};

Item.prototype = {

  activeItemsClass: "active",
  url: "",
  html: "",
  view: null,
  box: null,

  // Index in the item box.
  index: null,

  // Renders view and binds event handlers.
  buildView: function () {
    var item = this;
    this.view = this.render();
    this.view.click(function () {
      item.click();
      item.box.hide();
    }).mouseover(function () {
      item.box.deactivateSelection();
      item.box.currentItem = item.index;
      item.activate();
    });
    return this.view;
  },

  // Builds the actual DOM element.
  render: function () {
    return $(this.html);
  },

  // Action to be executed when the item is selected.
  click: function () {
    location.href = this.url;
  },

  // Activates the item view.
  activate: function () {
    this.view.addClass(this.activeItemsClass);
  },

  // Deactivates the item view.
  deactivate: function () {
    this.view.removeClass(this.activeItemsClass);
  }

};

// Builds a select-like box with items that can execute
// specific actions when clicked.
function ItemBox(container) {
  this.itemsContainer = $(container);
  this.itemsContainer.hide();
};

ItemBox.prototype = {

  items: [],
  currentItem: null,

  // Changes the set of items in the box.
  //
  // Receives an array of items in the order they should appear.
  setItems: function (items) {
    var box = this;

    // Clears previous items.
    this.itemsContainer.html("");
    this.items = items;
    this.currentItem = null;

    items.forEach(function (item, i) {
      item.box = box;
      item.index = i;
      box.itemsContainer.append(item.buildView());
    });
  },

  // Clears the content of the box.
  clear: function () {
    this.itemsContainer.html("");
    this.items = [];
    this.currentItem = null;
  },

  // Moves the current selection up.
  moveUp: function () {
    if (this.items.length == 0) return;
    if (this.currentItem == null) {
      this.items[this.items.length - 1].activate();
      this.currentItem = this.items.length - 1;
    } else {
      this.items[this.currentItem].deactivate();
      this.currentItem = this.currentItem == 0 ?
        this.items.length - 1 : this.currentItem - 1;
      this.items[this.currentItem].activate();
    }
  },

  // Moves the current selection down.
  moveDown: function () {
    if (this.items.length == 0) return;
    if (this.currentItem == null) {
      this.items[0].activate();
      this.currentItem = 0;
    } else {
      this.items[this.currentItem].deactivate();
      this.currentItem = this.currentItem == this.items.length - 1 ?
        0 : this.currentItem + 1;
      this.items[this.currentItem].activate();
    }
  },

  // Deactivates the current selection.
  deactivateSelection: function () {
    if (this.currentItem != null) {
      this.items[this.currentItem].deactivate();
      this.currentItem = null;
    }
  },

  // Runs the "click" event associated with the current active item.
  click: function () {
    if (this.currentItem != null)
      this.items[this.currentItem].click();
  },

  // Hides the box.
  hide: function () {
    this.itemsContainer.hide();
  },

  // Shows the box (i.e. make it visible).
  show: function () {
    this.itemsContainer.show();
  }

};

// Input field that contacts a server to look for suggestions.
function AutocompleteBox(inputField, itemBoxContainer, url) {

  var box = this;

  this.input = $(inputField);
  this.itemBox = new ItemBox(itemBoxContainer);
  this.itemBox.itemsContainer.mousedown(function () {
    box.selectionClicked = true;
  });
  this.url = url;
  this.initInputField();

};

AutocompleteBox.prototype = {

  startText: "",
  minChars: 2,
  ajaxRequest: null,

  // This is a hack to deal with inconsistencies in the order in which
  // DOM events are fired. Sometimes, the input box will receive focusout
  // and blur events before a clicked item receives any event. Therefore,
  // we need to be careful when hiding the selection box when the input
  // loses focus, since hiding it will prevent it from receiving click
  // events.
  selectionClicked: false,


  // Binds event handlers to input field.
  initInputField: function () {
    var box = this;
    var itemBox = this.itemBox;
    this.input.attr("autocomplete", "off").
      val(this.startText).
      focus(function () {
      if ($(this).val() == box.startText) {
        $(this).val("");
      } else if ($(this).val() != "") {
        itemBox.show();
      }
    }).blur(function () {
      if ($(this).val() == "") {
        $(this).val(box.startText);
      }
      if (!box.selectionClicked) {
        itemBox.hide();
      }
    }).keydown(function (e) {
      switch (e.keyCode) {
      case 38: // up
        e.preventDefault();
        itemBox.moveUp();
        break;
      case 40: // down
        e.preventDefault();
        itemBox.moveDown();
        break;
      case 13: // return
        e.preventDefault();
        itemBox.click();
        break;
      // ignore [escape] [shift] [capslock]
      case 27: case 16: case 20:
        box.abortRequest();
        itemBox.hide();
        break;
      default:
        box.fetchData($(this).val());
      }
    });
  },

  // Sends an AJAX request for items that match current input,
  // processes and renders them.
  fetchData: function (query) {
    if (query.length < this.minChars) return;
    var box = this;
    var fetchUrl = this.url + "?q=" + encodeURIComponent(query);
    this.abortRequest();
    this.ajaxRequest = $.getJSON(fetchUrl, function (data) {
      if (data) box.processData(data);
    });
  },

  // Aborts an AJAX request for items.
  abortRequest: function () {
    if (this.ajaxRequest) {
      this.ajaxRequest.abort();
      this.ajaxRequest = null;
    }
  }

};

function SearchItem(input) {
  this.query = input.val();
  this.form = input.parent("form");
}

SearchItem.prototype = {

  html: '<li class="search" />',

  render: function () {
    return $(this.html).text('Buscar por perguntas com "' + this.query + '"');
  },

  click: function () {
    this.form.submit();
  }

};

SearchItem.prototype = $.extend({}, Item.prototype, SearchItem.prototype);

// The all-purpose search box. Looks for questions, topics and users.
// Clicking a search result will take to the page of the corresponding
// entity. Also, displays an item that when clicked takes the user to the
// search page for questions.
function initSearchBox() {

  var searchBox = new AutocompleteBox("#search-field",
                                      "#search-results",
                                      "/search/autocomplete");

  searchBox.processData = function (data) {
    var items = [];
    data.forEach(function (item) {
      items.push(new Item(item));
    });
    items.push(new SearchItem(this.input));
    this.itemBox.setItems(items);
    this.itemBox.show();
  };

};

// Box to autocomplete and select topics when creating or editing questions.
function initTopicAutocomplete() {

  var topicBox = new AutocompleteBox("#question-topics-autocomplete",
                                   "#question-topics-suggestions",
                                   "/topics/autocomplete");

  var selectedTopicsUl = $("#selected-topics");
  $("#selected-topics span.remove").live("click", function () {
    $(this).parents("li").first().remove();
  });

  function TopicItemForAutocomplete(topic) {
    this.title = topic.title;
    this.count = topic.count;
    this.html = topic.html;
    this.topicBox = topic.box;
  }

  TopicItemForAutocomplete.prototype = {
    click: function () {
      selectedTopicsUl.append(this.topicBox);
      topicBox.itemBox.hide();
      topicBox.itemBox.clear();
      topicBox.input.val("");
    }
  };

  TopicItemForAutocomplete.prototype = $.extend({}, Item.prototype,
    TopicItemForAutocomplete.prototype);

  topicBox.processData = function (data) {

    // Ignore empty input.
    if (topicBox.input.val().trim() == "") return;

    var items = [];
    data.forEach(function (item) {
      items.push(new TopicItemForAutocomplete(item));
    });
    this.itemBox.setItems(items);
    this.itemBox.show();

  };

};