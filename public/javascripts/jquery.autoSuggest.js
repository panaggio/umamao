/*
 * AutoSuggest
 * Copyright 2009-2010 Drew Wilson
 * www.drewwilson.com
 * code.drewwilson.com/entry/autosuggest-jquery-plugin
 *
 * Forked by Wu Yuntao
 * github.com/wuyuntao/jquery-autosuggest
 *
 * Version 1.6.2
 *
 * This Plug-In will auto-complete or auto-suggest completed search queries
 * for you as you type. You can add multiple selections and remove them on
 * the fly. It supports keybord navigation (UP + DOWN + RETURN), as well
 * as multiple AutoSuggest fields on the same page.
 *
 * Inspied by the Autocomplete plugin by: J歳n Zaefferer
 * and the Facelist plugin by: Ian Tearle (iantearle.com)
 *
 * This AutoSuggest jQuery plug-in is dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 */

(function($){
    $.fn.autoSuggest = function (url, options) {
        var defaults = {
            asHtmlID: false,
            startText: "Enter Name Here",
            emptyText: "No Results Found",
            selectedItemProp: "value", // name of object property
            selectedValuesProp: "value", // name of object property
            queryParam: "q",
            retrieveLimit: false, // number for 'limit' param on ajax request
            extraParams: "",
            matchCase: false,
            minChars: 1,
            keyDelay: 400,
            resultsHighlight: true,
            neverSubmit: false,
            showResultList: true,
            showResultListWhenNoMatch: false,
            start: function () {},
            formatList: false, // callback function
            beforeRetrieve: function (string) { return string; },
            retrieveComplete: function (data) { return data; },
            resultClick: function (data) {},
            resultsComplete: function () {}
        };
        var opts = $.extend(defaults, options);

        var reqString = url;
        return this.each(function (x) {
            if (!opts.asHtmlID) {
                x = x+""+Math.floor(Math.random()*100); //this ensures there will be unique IDs on the page if autoSuggest() is called multiple times
                var xId = "as-input-"+x;
            } else {
                x = opts.asHtmlID;
                var xId = x;
            }
            opts.start.call(this);
            var input = $(this);
            input.attr("autocomplete", "off").addClass("as-input").attr("id", xId).val(opts.startText);
            var inputFocus = false;

            // Setup basic elements and render them to the DOM
            var resultsHolder = $('<div class="as-results" id="as-results-'+x+'" />').hide();
            var resultsUl =  $('<ul class="as-list" />');
            input.click(function () {
              inputFocus = true;
              input.focus();
            }).after(resultsHolder);

            var interval = null;
            var timeout = null;
            var prev = "";
            var totalSelections = 0;
            var tabPress = false;
            var lastKeyPressCode = null;
            var request = null;

            // Handle input field events
            input.focus(function () {
                if ($(this).val() == opts.startText) {
                    $(this).val("");
                } else if (inputFocus) {
                    if ($(this).val() != "") {
                        resultsHolder.show();
                    }
                }
                if (interval) clearInterval(interval);
                interval = setInterval(function() {
                    if (opts.showResultList) keyChange();
                }, opts.keyDelay);
                inputFocus = true;
                if (opts.minChars == 0){
                  processRequest($(this).val());
                }
                return true;
            }).blur(function () {
                if ($(this).val() == "") {
                    $(this).val(opts.startText);
                } else if (inputFocus) {
                    resultsHolder.hide();
                }
                if (interval) clearInterval(interval);
            }).keydown(function (e) {
                // track last key pressed
                lastKeyPressCode = e.keyCode;
                switch (e.keyCode) {
                    case 38: // up
                        e.preventDefault();
                        moveSelection("up");
                        break;
                    case 40: // down
                        e.preventDefault();
                        moveSelection("down");
                        break;
                    case 13: // return
                        tabPress = false;
                        var active = $("li.active:first", resultsHolder);
                        if (active.length > 0) {
                            active.click();
                            resultsHolder.hide();
                        }
                        if (opts.neverSubmit || active.length > 0) {
                            e.preventDefault();
                        }
                        break;
                    // ignore if the following keys are pressed: [escape] [shift] [capslock]
                    case 27: // escape
                    case 16: // shift
                    case 20: // capslock
                        abortRequest();
                        resultsHolder.hide();
                        break;
                }
            });

            function keyChange() {
                // Since most IME's do not trigger any key events, if we press [del]
                // and type some chinese character, `lastKeyPressCode` will still be [del].
                // This might cause problems so we move the line to key events section;
                // ignore if the following keys are pressed: [del] [shift] [capslock]
                var string = input.val().replace(/[\\]+|[\/]+/g,"");
                if (string == prev) return;
                prev = string;
                if (string.length >= opts.minChars) {
                    processRequest(string);
                } else {
                    resultsHolder.hide();
                }
            }

            function processRequest(string) {
                // Sends an AJAX request for items that match the query, process and render them.
                var limit = "";
                if (opts.retrieveLimit) {
                    limit = "&limit="+encodeURIComponent(opts.retrieveLimit);
                }
                if (opts.beforeRetrieve) {
                    string = opts.beforeRetrieve.call(this, string);
                }
                // Cancel previous request when input changes
                abortRequest();

                var url = reqString+"?"+opts.queryParam+"="+encodeURIComponent(string)+limit+opts.extraParams;
                // TODO handle aborted response
                request = $.getJSON(url, function (data) {
                    processData(opts.retrieveComplete.call(this, data), string);
                });
            }

            var numCount = 0;
            function processData(data, query) {
                // Renders the recieved data as DOM elements.
                if (!opts.matchCase) { query = query.toLowerCase(); }
                resultsHolder.html(resultsUl.html("")).hide();
                $.each(data, function (i, item) {
                    numCount++;
                    var formatted = $('<li class="as-result-item" id="as-result-item-'+i+'" />').click(function () {
                        var rawData = $(this).data("data");
                        var number = rawData.num;
                        if(!tabPress){
                            var data = rawData.attributes;
                            input.focus();
                            opts.resultClick.call(this, rawData);
                            resultsHolder.hide();
                        }
                        tabPress = false;
                    }).mousedown(function () {
                        inputFocus = false;
                    }).mouseover(function () {
                        $("li", resultsUl).removeClass("active");
                        $(this).addClass("active");
                    }).data("data", {attributes: item, num: numCount});
                    var thisData = $.extend({}, item);
                    var regx = new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + query + ")(?![^<>]*>)(?![^&;]+;)",
                                          opts.matchCase ? "g" : "gi");

                    if (opts.resultsHighlight && query.length > 0){
                        thisData[opts.selectedItemProp] = thisData[opts.selectedItemProp].replace(regx,"<em>$1</em>");
                    }
                    if (!opts.formatList) {
                        formatted = formatted.html(thisData[opts.selectedItemProp]);
                    } else {
                        formatted = opts.formatList.call(input, thisData, formatted);
                    }
                    resultsUl.append(formatted);
                    delete thisData;
                });
                if (data.length <= 0) {
                    resultsUl.html('<li class="as-message">'+opts.emptyText+'</li>');
                }
                if (data.length > 0 || !opts.showResultListWhenNoMatch) {
                    resultsHolder.show();
                }
                opts.resultsComplete.call(this);
            }

            function moveSelection(direction) {
                // Moves the current result selection up or down.
                if ($(":visible",resultsHolder).length > 0) {
                    var lis = $("li", resultsHolder);
                    if (direction == "down") {
                        var start = lis.eq(0);
                    } else {
                        var start = lis.filter(":last");
                    }
                    var active = $("li.active:first", resultsHolder);
                    if (active.length > 0) {
                        if (direction == "down") {
                            start = active.next();
                        } else {
                            start = active.prev();
                        }
                    }
                    lis.removeClass("active");
                    start.addClass("active");
                }
            }

            function abortRequest() {
                // Aborts an AJAX request for search results.
                if (request) {
                    request.abort();
                    request = null;
                }
            }

        });
    };
})(jQuery);
