RegExp.escape = (text) -> text.replace /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"
conn = new RDF.AjaxEndpointConnection("/sparql/")

lastQuery = false

sparqlPrefixes = """
    PREFIX uchile: <http://www.rdfclip.com/resources/uchile#>
    PREFIX uchiles: <http://www.rdfclip.com/schema/uchile#>
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX clip: <http://www.rdfclip.com/resource/>
    PREFIX clips: <http://www.rdfclip.com/schema#>
"""

row = {
  name: 'Support Vector Machines'
}

getKeywords = ->
  $textNodes = $(".textareaMagicDiv").contents().filter -> this.nodeType == Node.TEXT_NODE
  return $.trim($textNodes.text())

filteredSearchByCourse = (options) ->
  options.extraFilter = options.extraFilter || ""

  sparql = sparqlPrefixes + """
      SELECT ?file, ?label, "#{options.codigo}" as ?codigoCurso, ?link FROM <http://ucursos.rdfclip.com/> WHERE {
        ?file rdfs:label ?label .
        ?file clips:indirectDownloadLink ?link .
        ?file uchiles:instanciaCurso ?instancia .
        ?instancia uchiles:curso #{options.curso} .
        #{options.extraFilter}
      }
      LIMIT 10
  """
  options.sparql = sparql
  filteredSearch options

filteredSearchByContext = (options) ->
  options.extraFilter = options.extraFilter || ""

  sparql = sparqlPrefixes + """
      SELECT ?file, ?label, ?codigoCurso, ?link FROM <http://ucursos.rdfclip.com/> WHERE {
        ?file rdfs:label ?label .
        ?file clips:indirectDownloadLink ?link .
        ?file uchiles:instanciaCurso ?instancia .
        ?instancia uchiles:curso ?curso .
        ?curso uchiles:codigoCurso ?codigoCurso .
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
          link: row['link']
          uri: row['file']

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
      curso: "<#{course}>"
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

  courses = getSelectedCourses()
  courses_cond = ""

  if courses.length > 0
    conds = []
    for course in courses
      conds.push "?curso = <#{course}>"
    courses_cond = " FILTER(#{conds.join(" || ")}) "

  contexts = getSelectedContexts()
  contexts_cond = ""

  if contexts.length > 0
    conds = []
    for context in contexts
      conds.push "?context = <#{context}>"
    contexts_cond = " FILTER(#{conds.join(" || ")}) "

  filteredSearch(courses_cond)

searchCourses = (options) ->
    sparql = sparqlPrefixes+"""
        SELECT * FROM <http://ucursos.rdfclip.com/> WHERE {
          ?curso rdf:type uchiles:Curso .
          ?curso clips:userLabel ?userLabel .
          ?curso uchiles:codigoCurso ?codigo .
          FILTER regex(?userLabel, "^#{options.keyword}","i")
        }

        LIMIT 10
    """

    if lastQuery
      lastQuery.abort()

    lastQuery = conn.query
      query: sparql
      success: (r) =>
        out = []
        results = RDF.getResultSet(r)
        while row = results.fetchRow()
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

    if lastQuery
      lastQuery.abort()

    lastQuery = conn.query
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
    out.push $(elem).attr("data-course-uri")
  return out

getSelectedContexts = ->
  out = []
  for elem in $("[data-context-uri]")
    out.push $(elem).attr("data-context-uri")
  return out

require [], () ->

  $ ->
    $("input").val ""
    $(".btn-search").click ->
      searchFiles()
      toast getKeywords()
      return false

    magic = new MagicTextArea $("input")
    magic.suggestionTemplate = $("#suggest-item-tmpl")

    magic.addInlineSuggest
      trigger: 'NONE'
      refreshList: (word, list) ->
        toast word

        options = []
        if word.length < 2
          list.setOptions []
        else
          searchContext
            keyword: word
            success: (newOptions) ->
              options = options.concat newOptions
              list.setOptions options
          searchCourses
            keyword: word
            success: (newOptions) ->
              options = options.concat newOptions
              list.setOptions options

      parseCaretWord: (word, value) ->
        if value.type == "Curso"
          span = $("<span>").html(value.short_name).addClass("entity").attr("data-course-uri", value.uri)
        else
          span = $("<span>").html(value.short_name).addClass("entity").attr("data-context-uri", value.uri)

        return {
          span: span[0]
          tag: $("<div>").attr("title", value.long_name)[0]
        }
