from xml.etree import ElementTree
from rdflib import Graph, Literal, URIRef
from namespaces import CLIP, RDFS, UCHILE, UCHILES, CLIPS, RDF

class ElementWrapper(object):

    def __init__(self, file_or_element):
        if isinstance(file_or_element, basestring):
            with file(file_or_element) as f:
                self.element = ElementTree.fromstring(f.read())
        else:
            self.element = file_or_element

    def __getattr__(self, name):
        matches = self.element.iterfind(name)

        for match in matches:
            node = match

        if len(node) == 0:
            return node.text
        else:
            return ElementWrapper(node)

    def all(self, name):
        matches = self.element.iterfind(name)
        out = []

        for match in matches:
            out.append(ElementWrapper(match))

        return out

def parse_context(context):
    if context == "uchile":
        return "Comunidades UChile"

    words = context.split(" ")
    capitalized = [word[0].upper() + word[1:] for word in words if len(words) > 0]
    return ' '.join(capitalized)

def get_course_user_label(curso):

    return "%s: %s" % (curso.codigo, curso.nombre)

def xml_to_graph(filename):
    files = ElementWrapper(filename)
    graph = Graph()

    for material in files.all("material"):
        if material.md5 == "d41d8cd98f00b204e9800998ecf8427e":
            continue

        sub = CLIP[material.md5]
        graph.add((sub, RDFS['label'], Literal(material.titulo)))
        graph.add((sub, CLIPS['userLabel'], Literal(material.titulo)))

        contexto = UCHILE["contexto_%s" % material.curso.base]
        contexto_userlabel = parse_context(material.curso.base)
        instancia_curso = UCHILE['curso_%s_%s_%s_%s' %
            (material.curso.codigo.upper(), material.curso.anno,
            material.curso.semestre, material.curso.seccion)]
        curso = UCHILE["curso_%s" % material.curso.codigo.upper()]

        graph.add((curso, RDF['type'], UCHILES['Curso']))
        graph.add((sub, UCHILES['instanciaCurso'], instancia_curso))
        graph.add((sub, UCHILES['curso'], curso))
        graph.add((instancia_curso, UCHILES['curso'], curso))
        graph.add((curso, UCHILES['contextoCurso'], contexto))
        graph.add((contexto, RDFS['label'], material.curso.base))
        graph.add((contexto, CLIPS['userLabel'], contexto_userlabel))
        graph.add((curso, UCHILES['codigoCurso'],
            material.curso.codigo.upper()))
        graph.add((curso, RDFS['label'],
            material.curso.codigo.upper()))
        graph.add((curso, CLIPS['userLabel'],
            get_course_user_label(material.curso)))
        graph.add((sub, CLIPS['indirectDownloadLink'], URIRef(material.url)))

    return graph
