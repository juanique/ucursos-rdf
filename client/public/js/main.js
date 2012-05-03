(function() {
  var Synchronizer, conn, filteredSearch, filteredSearchByContext, filteredSearchByCourse, getKeywords, getSelectedContexts, getSelectedCourses, lastContextQuery, lastCoursesQuery, mergeRows, searchContext, searchCourses, searchFiles, sparqlPrefixes, suggestTo;

  Synchronizer = (function() {
    "The Synchronizer class allows to sync up a number of async calls.\n\nsynchronizer = new Synchronizer()\nsynchronizer.when ['ImReady','MeToo'], =>\n  doSomething()\n\nanAsyncProcess callback: => synchronizer.ready \"ImReady\"\nanotherAsyncProcess callback: => synchronizer.ready \"MeToo\"\n";
    function Synchronizer() {
      this.eventsReady = {};
      this.callbacks = [];
    }

    Synchronizer.prototype.ready = function(name) {
      this.eventsReady[name] = true;
      return this.triggerReadyCallbacks();
    };

    Synchronizer.prototype.when = function(events, callback) {
      this.callbacks.push({
        events: events,
        callback: callback
      });
      return this.triggerReadyCallbacks();
    };

    Synchronizer.prototype.triggerReadyCallbacks = function() {
      var data, event, _i, _j, _len, _len2, _ref, _ref2, _results;
      _ref = this.callbacks;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        data = _ref[_i];
        _ref2 = data.events;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          event = _ref2[_j];
          if (this.eventsReady[event]) data.events = _.without(data.events, event);
        }
        if (data.events.length === 0) {
          this.callbacks = _.without(this.callbacks, data);
          _results.push(typeof data.callback === "function" ? data.callback(null) : void 0);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    return Synchronizer;

  })();

  RegExp.escape = function(text) {
    return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
  };

  conn = new RDF.AjaxEndpointConnection("/sparql/");

  lastCoursesQuery = false;

  lastContextQuery = false;

  sparqlPrefixes = "PREFIX uchile: <http://www.rdfclip.com/resources/uchile#>\nPREFIX uchiles: <http://www.rdfclip.com/schema/uchile#>\nPREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\nPREFIX clip: <http://www.rdfclip.com/resource/>\nPREFIX clips: <http://www.rdfclip.com/schema#>";

  getKeywords = function() {
    var $textNodes;
    $textNodes = $(".textareaMagicDiv").contents().filter(function() {
      return this.nodeType === Node.TEXT_NODE;
    });
    return $.trim($textNodes.text());
  };

  filteredSearchByCourse = function(options) {
    var sparql;
    options.extraFilter = options.extraFilter || "";
    sparql = sparqlPrefixes + ("SELECT DISTINCT ?file, ?label, \"" + options.codigo + "\" as ?codigoCurso, ?link, ?directLink FROM <http://ucursos.rdfclip.com/> WHERE {\n  ?file rdfs:label ?label .\n  OPTIONAL {\n    ?file clips:indirectDownloadLink ?link .\n  }\n  OPTIONAL {\n    ?file clips:directDownloadLink ?directLink .\n  }\n  ?file uchiles:curso " + options.curso + " .\n  " + options.extraFilter + "\n}\nLIMIT 10");
    options.sparql = sparql;
    return filteredSearch(options);
  };

  filteredSearchByContext = function(options) {
    var sparql;
    options.extraFilter = options.extraFilter || "";
    sparql = sparqlPrefixes + ("SELECT DISTINCT ?file, ?label, ?curso, ?codigoCurso, ?link, ?directLink FROM <http://ucursos.rdfclip.com/> WHERE {\n  ?file rdfs:label ?label .\n  ?file uchiles:curso ?curso .\n  ?curso uchiles:codigoCurso ?codigoCurso .\n  OPTIONAL {\n    ?file clips:indirectDownloadLink ?link .\n  }\n  OPTIONAL {\n    ?file clips:directDownloadLink ?directLink .\n  }\n  " + options.extraFilter + "\n}\nLIMIT 10");
    options.sparql = sparql;
    return filteredSearch(options);
  };

  filteredSearch = function(options) {
    var _this = this;
    return conn.query({
      query: options.sparql,
      success: function(r) {
        var results, row, rows;
        rows = [];
        results = RDF.getResultSet(r);
        while (row = results.fetchRow()) {
          console.log(row['link']);
          rows.push({
            name: row['label'],
            codigo: row['codigoCurso'],
            link: row['link'] || "",
            uri: row['file'],
            directLink: row['directLink'] || ""
          });
        }
        return typeof options.success === "function" ? options.success(rows) : void 0;
      }
    });
  };

  mergeRows = function(rows, newRows) {
    var dupe, newRow, out, row, _i, _j, _k, _len, _len2, _len3, _results;
    out = [];
    for (_i = 0, _len = newRows.length; _i < _len; _i++) {
      newRow = newRows[_i];
      dupe = false;
      for (_j = 0, _len2 = rows.length; _j < _len2; _j++) {
        row = rows[_j];
        if (row['uri'] === newRow['uri']) {
          dupe = true;
          break;
        }
      }
      if (dupe) break;
      out.push(newRow);
    }
    _results = [];
    for (_k = 0, _len3 = out.length; _k < _len3; _k++) {
      row = out[_k];
      _results.push(rows.push(row));
    }
    return _results;
  };

  searchFiles = function() {
    var baseFilter, context, contexts, course, courses, extraFilter, keyword, rows, updateTable, _i, _j, _len, _len2,
      _this = this;
    courses = getSelectedCourses();
    contexts = getSelectedContexts();
    rows = [];
    updateTable = function() {
      var resultsHtml;
      resultsHtml = $("#results-table-tmpl").tmpl({
        rows: rows
      });
      return $(".results-container").html(resultsHtml);
    };
    baseFilter = "";
    keyword = getKeywords();
    if (keyword) baseFilter = "FILTER regex(?label, '" + keyword + "','i')";
    for (_i = 0, _len = courses.length; _i < _len; _i++) {
      course = courses[_i];
      extraFilter = baseFilter;
      filteredSearchByCourse({
        curso: "<" + course.uri + ">",
        codigo: course.codigo,
        extraFilter: extraFilter,
        success: function(newRows) {
          mergeRows(rows, newRows);
          return updateTable();
        }
      });
    }
    for (_j = 0, _len2 = contexts.length; _j < _len2; _j++) {
      context = contexts[_j];
      extraFilter = "?curso uchiles:contextoCurso <" + context + "> . " + baseFilter;
      filteredSearchByContext({
        extraFilter: extraFilter,
        success: function(newRows) {
          mergeRows(rows, newRows);
          return updateTable();
        }
      });
    }
  };

  searchCourses = function(options) {
    var sparql,
      _this = this;
    sparql = sparqlPrefixes + ("SELECT DISTINCT * FROM <http://ucursos.rdfclip.com/> WHERE {\n  ?curso rdf:type uchiles:Curso .\n  ?curso clips:userLabel ?userLabel .\n  ?curso uchiles:codigoCurso ?codigo .\n  FILTER regex(?userLabel, \"^" + options.keyword + "\",\"i\")\n}\n\nLIMIT 10");
    if (lastCoursesQuery) lastCoursesQuery.abort();
    return lastCoursesQuery = conn.query({
      query: sparql,
      success: function(r) {
        var exists, out, results, row, x, _i, _len;
        out = [];
        results = RDF.getResultSet(r);
        while (row = results.fetchRow()) {
          exists = false;
          for (_i = 0, _len = out.length; _i < _len; _i++) {
            x = out[_i];
            if (x['uri'] === row['curso'].value) {
              exists = true;
              break;
            }
          }
          if (!exists) {
            out.push({
              type: 'Curso',
              short_name: row['codigo'].value,
              long_name: row['userLabel'].value,
              uri: row['curso'].value
            });
          }
        }
        return typeof options.success === "function" ? options.success(out) : void 0;
      }
    });
  };

  searchContext = function(options) {
    var sparql,
      _this = this;
    sparql = sparqlPrefixes + ("SELECT DISTINCT ?label, ?userLabel, ?contexto FROM <http://ucursos.rdfclip.com/> WHERE {\n  ?curso rdf:type uchiles:Curso .\n  ?curso uchiles:contextoCurso ?contexto .\n  ?contexto clips:userLabel ?userLabel .\n  ?contexto rdfs:label ?label .\n  FILTER regex(?userLabel, \"^" + options.keyword + "\",\"i\")\n}\n\nLIMIT 10");
    if (lastContextQuery) lastContextQuery.abort();
    return lastContextQuery = conn.query({
      query: sparql,
      success: function(r) {
        var out, results, row;
        out = [];
        results = RDF.getResultSet(r);
        while (row = results.fetchRow()) {
          out.push({
            type: 'Contexto',
            short_name: row['label'].value,
            long_name: row['userLabel'].value,
            uri: row['contexto'].value
          });
        }
        return typeof options.success === "function" ? options.success(out) : void 0;
      }
    });
  };

  getSelectedCourses = function() {
    var elem, out, _i, _len, _ref;
    out = [];
    _ref = $("[data-course-uri]");
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      elem = _ref[_i];
      out.push({
        uri: $(elem).attr("data-course-uri"),
        codigo: $(elem).attr("data-course-code")
      });
    }
    return out;
  };

  getSelectedContexts = function() {
    var elem, out, _i, _len, _ref;
    out = [];
    _ref = $("[data-context-uri]");
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      elem = _ref[_i];
      out.push($(elem).attr("data-context-uri"));
    }
    return out;
  };

  suggestTo = false;

  require([], function() {
    return $(function() {
      var magic, searchingFor;
      $("input").val("");
      $(".btn-search").click(function() {
        searchFiles();
        return false;
      });
      magic = new MagicTextArea($("input"));
      magic.suggestionTemplate = $("#suggest-item-tmpl");
      searchingFor = false;
      return magic.addInlineSuggest({
        trigger: 'NONE',
        refreshList: function(word, list) {
          var options, suggest,
            _this = this;
          window.list = list;
          if (suggestTo) clearTimeout(suggestTo);
          options = [];
          suggest = function() {
            var sync;
            sync = new Synchronizer();
            sync.when(["courses", "contexts"], function() {
              toast("setting " + options.length + " options");
              return list.setOptions(options);
            });
            searchingFor = word;
            if (word.length < 2) {
              return list.setOptions([]);
            } else {
              searchContext({
                keyword: word,
                success: function(newOptions) {
                  if (word === searchingFor) {
                    options = options.concat(newOptions);
                    return sync.ready("contexts");
                  }
                }
              });
              return searchCourses({
                keyword: word,
                success: function(newOptions) {
                  if (word === searchingFor) {
                    options = options.concat(newOptions);
                    return sync.ready("courses");
                  }
                }
              });
            }
          };
          return suggestTo = setTimeout(suggest, 500);
        },
        parseCaretWord: function(word, value) {
          var span;
          if (value.type === "Curso") {
            span = $("<span>").html(value.short_name).addClass("entity").attr("data-course-uri", value.uri);
            span.attr("data-course-code", value.short_name);
          } else {
            span = $("<span>").html(value.short_name).addClass("entity").attr("data-context-uri", value.uri);
          }
          return {
            span: span[0],
            tag: $("<div>").attr("title", value.long_name)[0]
          };
        }
      });
    });
  });

}).call(this);
