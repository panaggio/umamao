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

        var req_string = url;
        return this.each(function (x) {
            if (!opts.asHtmlID) {
                x = x+""+Math.floor(Math.random()*100); //this ensures there will be unique IDs on the page if autoSuggest() is called multiple times
                var x_id = "as-input-"+x;
            } else {
                x = opts.asHtmlID;
                var x_id = x;
            }
            opts.start.call(this);
            var input = $(this);
            input.attr("autocomplete", "off").addClass("as-input").attr("id", x_id).val(opts.startText);
            var input_focus = false;

            // Setup basic elements and render them to the DOM
            input.wrap('<ul class="as-selections" id="as-selections-'+x+'" />').wrap('<li class="as-original" id="as-original-'+x+'" />');
            var selectionsHolder = $("#as-selections-"+x);
            var resultsHolder = $('<div class="as-results" id="as-results-'+x+'" />').hide();
            var resultsUl =  $('<ul class="as-list" />');

            selectionsHolder.click(function () {
                input_focus = true;
                input.focus();
            }).mousedown(function () {
                input_focus = false;
            }).after(resultsHolder);

            var interval = null;
            var timeout = null;
            var prev = "";
            var totalSelections = 0;
            var tab_press = false;
            var lastKeyPressCode = null;
            var request = null;

            // Handle input field events
            input.focus(function () {
                if ($(this).val() == opts.startText) {
                    $(this).val("");
                } else if (input_focus) {
                    if ($(this).val() != "") {
                        resultsUl.css("width",selectionsHolder.outerWidth());
                        resultsHolder.show();
                    }
                }
                if (interval) clearInterval(interval);
                interval = setInterval(function() {
                    if (opts.showResultList) keyChange();
                }, opts.keyDelay);
                input_focus = true;
                if (opts.minChars == 0){
                  processRequest($(this).val());
                }
                return true;
            }).blur(function () {
                if ($(this).val() == "") {
                    $(this).val(opts.startText);
                } else if(input_focus){
                    resultsHolder.hide();
                }
                if (interval) clearInterval(interval);
            }).keydown(function (e) {
                // track last key pressed
                lastKeyPressCode = e.keyCode;
                first_focus = false;
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
                        tab_press = false;
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
                    selectionsHolder.addClass("loading");
                    processRequest(string);
                } else {
                    selectionsHolder.removeClass("loading");
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

                var url = req_string+"?"+opts.queryParam+"="+encodeURIComponent(string)+limit+opts.extraParams;
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
                        var raw_data = $(this).data("data");
                        var number = raw_data.num;
                        if($("#as-selection-"+number, selectionsHolder).length <= 0 && !tab_press){
                            var data = raw_data.attributes;
                            input.val("").focus();
                            prev = "";
                            opts.resultClick.call(this, raw_data);
                            resultsHolder.hide();
                        }
                        tab_press = false;
                    }).mousedown(function () {
                        input_focus = false;
                    }).mouseover(function () {
                        $("li", resultsUl).removeClass("active");
                        $(this).addClass("active");
                    }).data("data", {attributes: item, num: numCount});
                    var this_data = $.extend({}, item);
                    var regx = new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + query + ")(?![^<>]*>)(?![^&;]+;)",
                                          opts.matchCase ? "g" : "gi");

                    if (opts.resultsHighlight && query.length > 0){
                        this_data[opts.selectedItemProp] = this_data[opts.selectedItemProp].replace(regx,"<em>$1</em>");
                    }
                    if (!opts.formatList) {
                        formatted = formatted.html(this_data[opts.selectedItemProp]);
                    } else {
                        formatted = opts.formatList.call(this, this_data, formatted);
                    }
                    resultsUl.append(formatted);
                    delete this_data;
                });
                selectionsHolder.removeClass("loading");
                if (data.length <= 0) {
                    resultsUl.html('<li class="as-message">'+opts.emptyText+'</li>');
                }
                resultsUl.css("width", selectionsHolder.outerWidth());
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
