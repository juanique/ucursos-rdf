from artichoke import Config
from ucursos import xml_to_graph
from virtuoso.endpoint import Endpoint
from virtuoso import ISQLWrapper
from testconfig import TestDefaultManager
import os

config = Config("local_test_config.ini",
    default_manager=TestDefaultManager())

url = "http://%s:%s%s"
url %= (config.host, config.endpoint_port,
    config.endpoint_path)

endpoint = Endpoint(url)
isql = ISQLWrapper(config.host, config.user,
    config.password)
isql.execute_cmd("SPARQL CLEAR GRAPH <%s>" % config.graph)

isql.load_file("uchile_schema.ttl", config.graph)

datadir = "../data"

for dirname, dirnames, filenames in os.walk(datadir):
    for filename in filenames:
        print filename
        full_path = os.path.join(dirname, filename)
        basename, extension = os.path.splitext(filename)

        try:
            graph = xml_to_graph(full_path)
            isql.insert(config.graph, graph)
            with file("data/%s.rdf" % basename, "w") as f:
                f.write(graph.serialize(format="xml"))
            print "written data/%s.rdf" % basename
        except Exception, e:
            print "Could not parse %s: %s" % (filename, e)

