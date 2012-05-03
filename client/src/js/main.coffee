class Synchronizer

  """
  The Synchronizer class allows to sync up a number of async calls.

  synchronizer = new Synchronizer()
  synchronizer.when ['ImReady','MeToo'], =>
    doSomething()

  anAsyncProcess callback: => synchronizer.ready "ImReady"
  anotherAsyncProcess callback: => synchronizer.ready "MeToo"

  """

  constructor: ->
    @eventsReady = {}
    @callbacks = []

  ready: (name) ->
    @eventsReady[name] = true
    @triggerReadyCallbacks()

  when: (events, callback) ->
    @callbacks.push
      events: events
      callback: callback
    @triggerReadyCallbacks()

  triggerReadyCallbacks: ->
    for data in @callbacks
      for event in data.events
        if @eventsReady[event]
          data.events = _.without data.events, event
      if data.events.length == 0
        @callbacks = _.without @callbacks, data
        data.callback? (null)


RegExp.escape = (text) -> text.replace /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"
conn = new RDF.AjaxEndpointConnection("/sparql/")

lastCoursesQuery = false
lastContextQuery= false

sparqlPrefixes = """
    PREFIX uchile: <http://www.rdfclip.com/resources/uchile#>
    PREFIX uchiles: <http://www.rdfclip.com/schema/uchile#>
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX clip: <http://www.rdfclip.com/resource/>
    PREFIX clips: <http://www.rdfclip.com/schema#>
"""

getKeywords = ->
  $textNodes = $(".textareaMagicDiv").contents().filter -> this.nodeType == Node.TEXT_NODE
  return $.trim($textNodes.text())

filteredSearchByCourse = (options) ->
  options.extraFilter = options.extraFilter || ""

  sparql = sparqlPrefixes + """
      SELECT DISTINCT ?file, ?label, "#{options.codigo}" as ?codigoCurso, ?link, ?directLink FROM <http://ucursos.rdfclip.com/> WHERE {
        ?file rdfs:label ?label .
        OPTIONAL {
          ?file clips:indirectDownloadLink ?link .
        }
        OPTIONAL {
          ?file clips:directDownloadLink ?directLink .
        }
        ?file uchiles:curso #{options.curso} .
        #{options.extraFilter}
      }
      LIMIT 10
  """
  options.sparql = sparql
  filteredSearch options

filteredSearchByContext = (options) ->
  options.extraFilter = options.extraFilter || ""

  sparql = sparqlPrefixes + """
      SELECT DISTINCT ?file, ?label, ?curso, ?codigoCurso, ?link, ?directLink FROM <http://ucursos.rdfclip.com/> WHERE {
        ?file rdfs:label ?label .
        ?file uchiles:curso ?curso .
        ?curso uchiles:codigoCurso ?codigoCurso .
        OPTIONAL {
          ?file clips:indirectDownloadLink ?link .
        }
        OPTIONAL {
          ?file clips:directDownloadLink ?directLink .
        }
        #{options.extraFilter}
      }
      LIMIT 10
  """
  options.sparql = sparql
  filteredSearch options

filteredSearch = (options) ->

  conn.query
    query: options.sparql
    success: (r) =>
      rows = []
      results = RDF.getResultSet(r)
      while row = results.fetchRow()
        console.log row['link']
        rows.push
          name: row['label']
          codigo: row['codigoCurso']
          link: row['link'] or ""
          uri: row['file']
          directLink: row['directLink'] or ""

      options.success? (rows)


mergeRows = (rows, newRows) ->
  out = []

  for newRow in newRows
    dupe = false
    for row in rows
      if row['uri'] == newRow['uri']
        dupe = true
        break
    if dupe
      break
    out.push newRow

  for row in out
    rows.push row

searchFiles = ->
  courses = getSelectedCourses()
  contexts = getSelectedContexts()

  rows = []

  updateTable = () =>
      resultsHtml = $("#results-table-tmpl").tmpl rows: rows
      $(".results-container").html resultsHtml

  baseFilter= ""
  keyword = getKeywords()

  if keyword
    baseFilter = "FILTER regex(?label, '#{keyword}','i')"

  for course in courses
    extraFilter = baseFilter
    filteredSearchByCourse
      curso: "<#{course.uri}>"
      codigo: course.codigo
      extraFilter: extraFilter
      success: (newRows) ->
        mergeRows(rows, newRows)
        updateTable()


  for context in contexts
    extraFilter = "?curso uchiles:contextoCurso <#{context}> . #{baseFilter}"
    filteredSearchByContext
      extraFilter: extraFilter
      success: (newRows) ->
        mergeRows(rows, newRows)
        updateTable()

  return

searchCourses = (options) ->
    sparql = sparqlPrefixes+"""
        SELECT DISTINCT * FROM <http://ucursos.rdfclip.com/> WHERE {
          ?curso rdf:type uchiles:Curso .
          ?curso clips:userLabel ?userLabel .
          ?curso uchiles:codigoCurso ?codigo .
          FILTER regex(?userLabel, "^#{options.keyword}","i")
        }

        LIMIT 10
    """

    if lastCoursesQuery
      lastCoursesQuery.abort()

    lastCoursesQuery = conn.query
      query: sparql
      success: (r) =>
        out = []
        results = RDF.getResultSet(r)
        while row = results.fetchRow()
          exists = false
          for x in out
            if x['uri'] == row['curso'].value
              exists = true
              break

          if not exists
            out.push
              type: 'Curso'
              short_name: row['codigo'].value
              long_name: row['userLabel'].value
              uri: row['curso'].value

        options.success? (out)

searchContext = (options) ->
    sparql = sparqlPrefixes+"""
        SELECT DISTINCT ?label, ?userLabel, ?contexto FROM <http://ucursos.rdfclip.com/> WHERE {
          ?curso rdf:type uchiles:Curso .
          ?curso uchiles:contextoCurso ?contexto .
          ?contexto clips:userLabel ?userLabel .
          ?contexto rdfs:label ?label .
          FILTER regex(?userLabel, "^#{options.keyword}","i")
        }

        LIMIT 10
    """

    if lastContextQuery
      lastContextQuery.abort()

    lastContextQuery = conn.query
      query: sparql
      success: (r) =>
        out = []
        results = RDF.getResultSet(r)
        while row = results.fetchRow()
          out.push
            type: 'Contexto'
            short_name: row['label'].value
            long_name: row['userLabel'].value
            uri: row['contexto'].value

        options.success? (out)

getSelectedCourses = ->
  out = []
  for elem in $("[data-course-uri]")
    out.push
      uri: $(elem).attr("data-course-uri")
      codigo: $(elem).attr("data-course-code")
  return out

getSelectedContexts = ->
  out = []
  for elem in $("[data-context-uri]")
    out.push $(elem).attr("data-context-uri")
  return out

suggestTo = false

require [], () ->

  $ ->
    $("input").val ""
    $(".btn-search").click ->
      searchFiles()
      return false

    magic = new MagicTextArea $("input")
    magic.suggestionTemplate = $("#suggest-item-tmpl")
    searchingFor = false

    magic.addInlineSuggest
      trigger: 'NONE'
      refreshList: (word, list) ->
        window.list = list

        if suggestTo
          clearTimeout(suggestTo)

        options = []

        suggest = =>
          sync = new Synchronizer()
          sync.when ["courses", "contexts"], =>
              toast "setting #{options.length} options"
              list.setOptions options


          searchingFor = word
          if word.length < 2
            list.setOptions []
          else
            searchContext
              keyword: word
              success: (newOptions) ->
                if word == searchingFor
                  options = options.concat newOptions
                  sync.ready("contexts")

            searchCourses
              keyword: word
              success: (newOptions) ->
                if word == searchingFor
                  options = options.concat newOptions
                  sync.ready("courses")

        suggestTo = setTimeout(suggest, 500)

      parseCaretWord: (word, value) ->
        if value.type == "Curso"
          span = $("<span>").html(value.short_name).addClass("entity").attr("data-course-uri", value.uri)
          span.attr("data-course-code", value.short_name)
        else
          span = $("<span>").html(value.short_name).addClass("entity").attr("data-context-uri", value.uri)

        return {
          span: span[0]
          tag: $("<div>").attr("title", value.long_name)[0]
        }
