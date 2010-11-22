// Autocomplete boxes used throughout the site.
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
// Meant to be inherited.
function Item() { };

Item.prototype = {

  itemsClass: "item-box-item",
  activeItemsClass: "item-box-active-item",
  url: null,
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
  // Meant to be implemented by inheriting classes.
  render: function () { },

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
  this.itemsUl = $('<ul />').addClass(this.itemsUlClass);
  this.itemsContainer.append(this.itemsUl).hide();
};

ItemBox.prototype = {

  itemsUlClass: "item-box-list",
  items: [],
  currentItem: null,

  // Changes the set of items in the box.
  //
  // Receives an array of items in the order they should appear.
  setItems: function (items) {
    var box = this;

    // Clears previous items.
    this.itemsUl.html("");
    this.items = items;
    this.currentItem = null;

    items.forEach(function (item, i) {
      item.box = box;
      item.index = i;
      box.itemsUl.append(item.buildView());
    });
  },

  // Clears the content of the box.
  clear: function () {
    this.itemsUl.html("");
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

// Each specific kind of item we have in autocomplete boxes.

function QuestionItem(data) {
  this.title = data.title;
  this.url = data.url;
  this.topics = data.topics;
};

// Not a very clever way of inheriting, but...
QuestionItem.prototype = new Item();

QuestionItem.prototype.render = function () {
  return $('<li />').addClass("item-box-item").text(this.title + " ").
    append($('<span class="desc" />').text(this.topics.join(", ")));
};

function TopicItem(data) {
  this.title = data.title;
  this.url = data.url;
};

TopicItem.prototype = new Item();

TopicItem.prototype.render = function () {
  return $('<li />').addClass("item-box-item").text(this.title).
    append(' <span class="desc">Tópico</span>');
};

function UserItem(data) {
  this.name = data.title;
  this.picture = data.pic;
  this.url = data.url;
};

UserItem.prototype = new Item();

UserItem.prototype.render = function () {
  var picture = $(this.picture);
  return $('<li />').addClass("item-box-item").text(" " + this.name).prepend(picture);
};

// The all-purpose search box. Looks for questions, topics and users.
// Clicking a search result will take to the page of the corresponding
// entity. Also, displays an item that when clicked takes the user to the
// search page for questions.
function initSearchBox() {
  var searchBox = new AutocompleteBox("#search-field",
                                      "#autocomplete-results",
                                      "/search/json");

  function makeItem(data) {
    switch (data.type) {
    case "Question":
      return new QuestionItem(data);
    case "Topic":
      return new TopicItem(data);
    case "User":
      return new UserItem(data);
    }
    return null;
  };

  function makeSearchItem() {
    searchItem = new Item();
    searchItem.render = function () {
      return $('<li />').addClass("item-box-search").
        addClass("item-box-item").
        text('Buscar por perguntas com "' + searchBox.input.val() + '"');
    };
    searchItem.click = function () {
      searchBox.input.parent().submit();
    };
    return searchItem;
  };

  searchBox.processData = function (data) {
    var items = [];
    data.forEach(function (item) {
      items.push(makeItem(item));
    });
    items.push(makeSearchItem());
    this.itemBox.setItems(items);
    this.itemBox.show();
  };
};


// Box to autocomplete and select topics when creating or editing questions.
function initTopicAutocomplete() {

  var topicBox = new AutocompleteBox("#question-topics-autocomplete",
                                   "#question-topics-suggestions",
                                   "/questions/tags_for_autocomplete.js");

  var selectedTopicsUl = $("#selected-topics");
  $("#selected-topics span.remove").live("click", function () {
    $(this).parents("li").first().remove();
  });

  // Adds a topic to the list of selected topics.
  function addTopic(topic) {
    var topicLi = $('<li class="topic"/>').text(topic.title);
    var topicInput = $('<input type="hidden" name="question[topics][]" />').
      val(topic.title);
    // TODO: make this a link, or use checkboxes to add/remove many topics
    var topicRemove = $('<span class="remove">✕</span>');
    selectedTopicsUl.append(topicLi.append(topicInput).
                            append(topicRemove).append('<div class="clear" />'));
  }

  function TopicItemForAutocomplete(topic) {
    this.title = topic.title;
    this.count = topic.count;
  }

  TopicItemForAutocomplete.prototype = new Item();

  TopicItemForAutocomplete.prototype.render = function () {
    return $('<li />').addClass("item-box-item").text(this.title + " ").
      append($('<span class="desc">' + this.count +
               ' ' + (this.count == 1 ? "questão" : "questões") + '</span>'));
  };

  TopicItemForAutocomplete.prototype.click = function () {
    addTopic(this);
    topicBox.itemBox.hide();
    topicBox.itemBox.clear();
    topicBox.input.val("");
  };

  topicBox.processData = function (data) {

    // Ignore empty input.
    if (topicBox.input.val().trim() == "") return;

    var items = [];
    var re = new RegExp("^" +  Utils.escapeRegExp(topicBox.input.val()) + "$", "i");
    if (!data.some(function (item) { return re.test(item.value); })) {
      data.push({title: topicBox.input.val(), count: 0});
    }
    data.forEach(function (item) {
      items.push(new TopicItemForAutocomplete(item));
    });
    this.itemBox.setItems(items);
    this.itemBox.show();

  };

};