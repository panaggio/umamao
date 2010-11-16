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
  minChars: 1,
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
        box.fetchData(box.preprocessInput($(this).val()));
      }
    });
  },

  // Pre-processes user input before sending
  preprocessInput: function (input) {
    return input;
  },

  // Sends an AJAX request for items that match current input,
  // processes and renders them.
  fetchData: function (query) {
    var box = this;
    var fetchUrl = this.url + "?q=" + encodeURIComponent(query);
    this.abortRequest();
    this.ajaxRequest = $.getJSON(fetchUrl, function (data) {
      if (data) box.processData(data);
    });
  },

  // Passes the received data items to the item box.
  processData: function (data) { },

  // Aborts an AJAX request for items.
  abortRequest: function () {
    if (this.ajaxRequest) {
      this.ajaxRequest.abort();
      this.ajaxRequest = null;
    }
  }

};

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



function initTopicAutocomplete() {
  var tagBox = new AutocompleteBox("#question-topics-autocomplete",
                                   "#question-topics-suggestions",
                                   "/questions/tags_for_autocomplete.js");

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

  tagBox.preprocessInput = function (input) {
    return input.replace(/\".*?\"\s*/g, "");
  },

  TopicItemForAutocomplete.prototype.click = function () {
    var oldTopics = tagBox.input.val().replace(/((?:\".*?\"\s*)*).*/, "$1");
    var newTopic = '"' + this.title.replace(/\"/g, '\\"') + '" ';
    tagBox.input.val(oldTopics.length != 0 ? oldTopics + " " + newTopic : newTopic);
    tagBox.itemBox.clear();
    tagBox.itemBox.hide();
  };

  tagBox.processData = function (data) {
    var items = [];
    var re = new RegExp("^" +  tagBox.input.val() + "$", "i");
    if (!data.some(function (item) { return re.test(item.value); })) {
      data.push({title: tagBox.preprocessInput(tagBox.input.val()), count: 0});
    }
    data.forEach(function (item) {
      items.push(new TopicItemForAutocomplete(item));
    });
    this.itemBox.setItems(items);
    this.itemBox.show();
  };
};