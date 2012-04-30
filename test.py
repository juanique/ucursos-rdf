import unittest

from namespaces import RDFS
from artichoke import Config
from ucursos import ElementWrapper, xml_to_graph
from virtuoso.endpoint import Endpoint
from virtuoso import ISQLWrapper
from testconfig import TestDefaultManager

class RDFTestCase(unittest.TestCase):

    def setUp(self):
        self.config = Config("local_test_config.ini",
            default_manager=TestDefaultManager())

        url = "http://%s:%s%s"
        url %= (self.config.host, self.config.endpoint_port,
            self.config.endpoint_path)

        self.endpoint = Endpoint(url)
        self.isql = ISQLWrapper(self.config.host, self.config.user,
            self.config.password)
        self.isql.execute_cmd("SPARQL CLEAR GRAPH <%s>" % self.config.graph)

    def tearDown(self):
        self.config.save("local_test_config.ini")
        self.isql.execute_cmd("SPARQL CLEAR GRAPH <%s>" % self.config.graph)

class UCursosTests(RDFTestCase):

    def test_upload_schema(self):
        self.isql.load_file("uchile_schema.ttl", self.config.graph)
        results = self.endpoint.query("""
            PREFIX uchile: <http://www.rdfclip.com/schema/uchile#>
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            SELECT ?type WHERE {
                uchile:Curso rdf:type ?type
            }
        """)
        self.assertEquals(results[0]['type'].value, str(RDFS['Class']))

    def test_testsuite(self):
        self.assertEqual(2, 1+1)

    def test_parse(self):
        data = ElementWrapper("data.xml")

        files = data.all("material")
        self.assertEqual("Corte1.mp3", files[0].titulo)
        self.assertEqual("mp3", files[0].extension)
        self.assertEqual("uchile", files[0].curso.base)

class QueriesTests(RDFTestCase):

    def get_data(self, md5):
        results = self.endpoint.query("""
            PREFIX uchile: <http://www.rdfclip.com/resources/uchile#>
            PREFIX uchiles: <http://www.rdfclip.com/schema/uchile#>
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
            PREFIX clip: <http://www.rdfclip.com/resource/>

            SELECT * WHERE {
                %s ?p ?o.
            }
        """ % md5)

        data = []
        for row in results:
            data.append("%s %s" % (row['p'].value, row['o'].value))
        return '\n'.join(data)

    def setUp(self):
        super(QueriesTests, self).setUp()
        self.isql.load_file("uchile_schema.ttl", self.config.graph)
        self.isql.insert(self.config.graph, xml_to_graph("data.xml"))

    def test_load_label(self):
        md5 = "4ec2498fd3e07f46ecda4c44e5ff9f35"

        query = """
            PREFIX uchile: <http://www.rdfclip.com/resources/uchile#>
            PREFIX uchiles: <http://www.rdfclip.com/schema/uchile#>
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
            PREFIX clip: <http://www.rdfclip.com/resource/>
            PREFIX clips: <http://www.rdfclip.com/schema#>

            SELECT * WHERE {
                clip:%(md5)s rdfs:label ?materialLabel .
                clip:%(md5)s uchiles:instanciaCurso ?instancia .
                ?instancia uchiles:curso ?curso .
                ?curso uchiles:contextoCurso ?contexto .
                ?contexto rdfs:label ?contextoLabel .
                ?contexto clips:userLabel ?contextoUserLabel .
            }
        """ % {'md5': md5}

        results = self.endpoint.query(query)

        self.assertEquals('Corte1.mp3', results[0]['materialLabel'].value)
        self.assertEquals('Comunidades UChile',
            results[0]['contextoUserLabel'].value)

    def test_load_context(self):

        md5 = "82c71c66a931ea71c9e2329a080f4371"

        query = """
            PREFIX uchile: <http://www.rdfclip.com/resources/uchile#>
            PREFIX uchiles: <http://www.rdfclip.com/schema/uchile#>
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
            PREFIX clip: <http://www.rdfclip.com/resource/>
            PREFIX clips: <http://www.rdfclip.com/schema#>

            SELECT * WHERE {
                clip:%(md5)s uchiles:instanciaCurso ?instancia .
                ?instancia uchiles:curso ?curso .
                ?curso uchiles:contextoCurso ?contexto .
                ?contexto rdfs:label ?contextoLabel .
                ?contexto clips:userLabel ?contextoUserLabel .
            }
        """ % {'md5': md5}

        results = self.endpoint.query(query)

        self.assertEquals('Ingenieria',
            results[0]['contextoUserLabel'].value)

    def test_load_course(self):

        md5 = "82c71c66a931ea71c9e2329a080f4371"

        query = """
            PREFIX uchile: <http://www.rdfclip.com/resources/uchile#>
            PREFIX uchiles: <http://www.rdfclip.com/schema/uchile#>
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
            PREFIX clip: <http://www.rdfclip.com/resource/>
            PREFIX clips: <http://www.rdfclip.com/schema#>

            SELECT * WHERE {
                clip:%(md5)s uchiles:instanciaCurso ?instancia .
                ?instancia uchiles:curso ?curso .
                ?curso uchiles:codigoCurso ?codigo .
                ?curso rdfs:label ?cursoLabel.
                ?curso clips:userLabel ?cursoUserLabel.
            }
        """ % {'md5': md5}

        results = self.endpoint.query(query)

        self.assertEquals('EL69E', results[0]['codigo'].value)
        self.assertEquals(u'EL69E: Introducci\xc3\xb3n al Trabajo de T\xc3\xadtulo', results[0]['cursoUserLabel'].value)


if __name__ == "__main__":
    unittest.main()
