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

searchFiles = ->
  courses = getSelectedCourses()
  courses_cond = ""

  if courses.length > 0
    conds = []
    for course in courses
      conds.push "?curso = <#{course}>"
    courses_cond = " FILTER(#{conds.join(" || ")}) "

  sparql = sparqlPrefixes + """
      SELECT ?label, ?codigoCurso, ?link FROM <http://ucursos.rdfclip.com/> WHERE {
        ?file rdfs:label ?label .
        ?file clips:indirectDownloadLink ?link .
        ?file uchiles:instanciaCurso ?instancia .
        ?instancia uchiles:curso ?curso .
        ?curso uchiles:codigoCurso ?codigoCurso
        #{courses_cond}
      }

      LIMIT 10
  """

  conn.query
    query: sparql
    success: (r) =>
      rows = []
      results = RDF.getResultSet(r)
      while row = results.fetchRow()
        rows.push
          name: row['label']
          codigo: row['codigoCurso']
          link: row['link']

      resultsHtml = $("#results-table-tmpl").tmpl rows: rows
      $(".results-container").html resultsHtml

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

getSelectedCourses = ->
  out = []
  for elem in $("[data-course-uri]")
    out.push $(elem).attr("data-course-uri")
  return out

require [], () ->

  $ ->
    $("input").val ""
    $(".btn-search").click ->
      searchFiles()
      console.log getSelectedCourses()
      console.log getSelectedCourses()[0]
      return false

    magic = new MagicTextArea $("input")
    magic.suggestionTemplate = $("#suggest-item-tmpl")

    magic.addInlineSuggest
      trigger: 'NONE'
      refreshList: (word, list) ->
        toast word

        if word.length < 2
          list.setOptions []
        else
          searchCourses
            keyword: word
            success: (options) ->
              list.setOptions options
      parseCaretWord: (word, value) ->
        span = $("<span>").html(value.short_name).addClass("entity").attr("data-course-uri", value.uri)

        return {
          span: span[0]
          tag: $("<div>").attr("title", value.long_name)[0]
        }
